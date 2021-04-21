import Vapor
import class NIOConcurrencyHelpers.NIOAtomic
import class NIO.RepeatedTask

/// The command to start the Queue job
public final class QueuesCommand: Command {
    /// See `Command.signature`
    public let signature = Signature()

    /// See `Command.Signature`
    public struct Signature: CommandSignature {
        public init() { }

        @Option(name: "queue", help: "Specifies a single queue to run")
        var queue: String?

        @Flag(name: "scheduled", help: "Runs the scheduled queue jobs")
        var scheduled: Bool
    }

    /// See `Command.help`
    public var help: String {
        return "Starts the Vapor Queues worker"
    }

    private let application: Application
    private var jobTasks: [RepeatedTask]
    private var scheduledTasks: [String: AnyScheduledJob.Task]
    private var lock: Lock
    private var signalSources: [DispatchSourceSignal]
    private var didShutdown: Bool

    private let isShuttingDown: NIOAtomic<Bool>

    private var eventLoopGroup: EventLoopGroup {
        self.application.eventLoopGroup
    }

    /// Create a new `QueueCommand`
    public init(application: Application, scheduled: Bool = false) {
        self.application = application
        self.jobTasks = []
        self.scheduledTasks = [:]
        self.isShuttingDown = .makeAtomic(value: false)
        self.signalSources = []
        self.didShutdown = false
        self.lock = .init()
    }

    /// Runs the command
    /// - Parameters:
    ///   - context: A `CommandContext` for the command to run on
    ///   - signature: The signature of the command
    public func run(using context: CommandContext, signature: QueuesCommand.Signature) throws {
        self.application.logger.trace("Beginning the run function")

        // shutdown future
        let promise = self.application.eventLoopGroup.next().makePromise(of: Void.self)
        self.application.running = .start(using: promise)

        // setup signal sources for shutdown
        let signalQueue = DispatchQueue(label: "codes.vapor.jobs.command")
        func makeSignalSource(_ code: Int32) {
            let source = DispatchSource.makeSignalSource(signal: code, queue: signalQueue)
            source.setEventHandler {
                print() // clear ^C
                promise.succeed(())
            }
            source.resume()
            self.signalSources.append(source)
            signal(code, SIG_IGN)
        }
        makeSignalSource(SIGTERM)
        makeSignalSource(SIGINT)

        if signature.scheduled {
            self.application.logger.info("Starting scheduled jobs worker")
            try self.startScheduledJobs()
        } else {
            let queue: QueueName = signature.queue
                .flatMap { .init(string: $0) } ?? .default
            self.application.logger.info("Starting jobs worker", metadata: ["queue": .string(queue.string)])
            try self.startJobs(on: queue)
        }
    }

    /// Starts an in-process jobs worker for queued tasks
    /// - Parameter queueName: The queue to run the jobs on
    public func startJobs(on queueName: QueueName) throws {
        let workerCount: Int
        switch self.application.queues.configuration.workerCount {
        case .default:
            var count = 0
            for _ in self.eventLoopGroup.makeIterator() {
                count += 1
            }
            workerCount = count
            self.application.logger.trace("Default workerCount, setting to \(workerCount)")
        case .custom(let custom):
            workerCount = custom
            self.application.logger.trace("Custom workerCount, setting to \(workerCount)")
        }
        for i in 0..<workerCount {
            self.application.logger.trace("Booting worker: \(i)")
            let eventLoop = self.eventLoopGroup.next()
            let worker = self.application.queues.queue(queueName, on: eventLoop).worker
            let task = eventLoop.scheduleRepeatedAsyncTask(
                initialDelay: .seconds(0),
                delay: worker.queue.configuration.refreshInterval
            ) { task in
                self.application.logger.trace("Running refresh task")

                // run task
                return worker.run().map {
                    self.application.logger.trace("Worker ran the task successfully")
                    // Check if shutting down
                    if self.isShuttingDown.load() {
                        self.application.logger.trace("Shutting down, cancelling the task")
                        task.cancel()
                    }
                }.recover { error in
                    worker.queue.logger.error("Job run failed: \(error)")
                }
            }
            self.jobTasks.append(task)
        }

        self.application.logger.trace("Finished adding jobTasks, total count: \(jobTasks.count)")
    }

    /// Starts the scheduled jobs in-process
    public func startScheduledJobs() throws {
        self.application.logger.trace("Checking for scheduled jobs to begin the worker")

        /// Adding builders of the containers who have the same `ScheduledJob`
        /// together to avoid unnecessary memory usage by the containers
        let containers = self.application.queues.configuration.scheduledJobsContainers
        var unneededContainersIndices: Set<Int> = .init()
        for (index, container) in containers.enumerated() {
            for (idx, cont) in containers.enumerated() {
                if (idx > index)
                    && (container.job.name == cont.job.name)
                    && !unneededContainersIndices.contains(index) {
                    let builders = cont.builders.map {
                        builder -> ScheduleContainer.Builder in
                        /// Setting builder's container to its new container
                        builder.container = container
                        return builder
                    }
                    container.builders += builders
                    unneededContainersIndices.insert(idx)
                }
            }
        }
        /// Removing the containers whose builders are added to another container
        for (idx, containerIndex) in unneededContainersIndices.sorted().enumerated() {
            self.application.queues.configuration.scheduledJobsContainers
                .remove(at: containerIndex - idx)
        }

        let scheduledJobs = self.application.queues.configuration.scheduledJobs
        guard !scheduledJobs.isEmpty else {
            self.application.logger.warning("No scheduled jobs exist, exiting scheduled jobs worker.")
            return
        }

        self.application.logger.trace("Beginning the scheduling process")
        scheduledJobs.forEach {
            self.application.logger.trace("Scheduling \($0.job.name)")
            self.schedule($0)
        }
    }

    private func schedule(_ job: AnyScheduledJob) {
        if self.isShuttingDown.load() {
            self.application.logger.trace("Application is shutting down, cancelling scheduling \(job.job.name)")
            return
        }

        self.lock.lock()
        defer { self.lock.unlock() }

        let context = QueueContext(
            queueName: QueueName(string: "scheduled"),
            configuration: self.application.queues.configuration,
            application: self.application,
            logger: self.application.logger,
            on: self.eventLoopGroup.next()
        )

        if let task = job.schedule(context: context) {
            self.application.logger.trace("Job \(job.job.name) was scheduled successfully")
            self.scheduledTasks[job.job.name] = task
            task.done.whenComplete { result in
                switch result {
                case .failure(let error):
                    context.logger.error("\(job.job.name) failed: \(error)")
                case .success: break
                }
                self.schedule(job)
            }
        }
    }

    /// Shuts down the jobs worker
    public func shutdown() {
        self.lock.lock()
        defer { self.lock.unlock() }

        self.isShuttingDown.store(true)
        self.didShutdown = true

        // stop running in case shutting downf rom signal
        self.application.running?.stop()

        // clear signal sources
        self.signalSources.forEach { $0.cancel() } // clear refs
        self.signalSources = []

        // stop all job queue workers
        self.jobTasks.forEach {
            $0.syncCancel(on: self.eventLoopGroup.next())
        }
        // stop all scheduled jobs
        self.scheduledTasks.values.forEach {
            $0.task.syncCancel(on: self.eventLoopGroup.next())
        }
    }

    deinit {
        assert(self.didShutdown, "JobsCommand did not shutdown before deinit")
    }
}
