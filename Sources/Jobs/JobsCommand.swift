import Vapor
import class NIOConcurrencyHelpers.NIOAtomic
import class NIO.RepeatedTask

/// The command to start the Queue job
public final class JobsCommand: Command {
    /// See `Command.signature`
    public let signature = Signature()
    
    /// See `Command.Signature`
    public struct Signature: CommandSignature {
        public init() { }
        
        @Option(name: "queue", help: "Specifies a single queue to run")
        var queue: String?
        
        @Flag(name: "scheduled", help: "Runs the scheduled jobs")
        var scheduled: Bool
    }
    
    /// See `Command.help`
    public var help: String {
        return "Starts the Vapor Jobs worker"
    }
    
    private let application: Application
    private var jobTasks: [RepeatedTask]
    private var scheduledTasks: [String: AnyScheduledJob.Task]
    private var lock: Lock
    private var signalSources: [DispatchSourceSignal]
    private var didShutdown: Bool
    
    
    let isShuttingDown: NIOAtomic<Bool>
    
    private var eventLoopGroup: EventLoopGroup {
        self.application.eventLoopGroup
    }

    /// Create a new `JobsCommand`
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
    public func run(using context: CommandContext, signature: JobsCommand.Signature) throws {
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
            let queue: JobsQueueName = signature.queue
                .flatMap { .init(string: $0) } ?? .default
            self.application.logger.info("Starting jobs worker (queue: \(queue.string))")
            try self.startJobs(on: queue)
        }
    }
    
    /// Starts an in-process jobs worker for queued tasks
    /// - Parameter queueName: The queue to run the jobs on
    public func startJobs(on queueName: JobsQueueName) throws {
        for eventLoop in eventLoopGroup.makeIterator() {
            let worker = self.application.jobs.queue(queueName).worker
            let task = eventLoop.scheduleRepeatedAsyncTask(
                initialDelay: .seconds(0),
                delay: worker.queue.configuration.refreshInterval
            ) { task in
                // run task
                return worker.run().map {
                    //Check if shutting down
                    if self.isShuttingDown.load() {
                        task.cancel()
                    }
                }.recover { error in
                    worker.queue.logger.error("Job run failed: \(error)")
                }
            }
            self.jobTasks.append(task)
        }
    }
    
    /// Starts the scheduled jobs in-process
    public func startScheduledJobs() throws {
        guard !self.application.jobs.configuration.scheduledJobs.isEmpty else {
            self.application.logger.warning("No scheduled jobs exist, exiting scheduled jobs worker.")
            return
        }
        
        self.application.jobs.configuration.scheduledJobs
            .forEach { self.schedule($0) }
    }
    
    private func schedule(_ job: AnyScheduledJob) {
        if self.isShuttingDown.load() {
            return
        }
        
        let context = JobContext(
            queueName: JobsQueueName(string: "scheduled"),
            configuration: self.application.jobs.configuration,
            logger: self.application.logger,
            on: self.eventLoopGroup.next()
        )
        
        if let task = job.schedule(context: context) {
            self.lock.withLock {
                self.scheduledTasks[job.job.name] = task
            }
            task.done.whenComplete { _ in
                self.schedule(job)
            }
        }
    }
    
    /// Shuts down the jobs worker
    public func shutdown() {
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
