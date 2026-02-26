import ConsoleKit
@preconcurrency import Dispatch
import Vapor
import NIOConcurrencyHelpers
import NIOCore
import Atomics

/// The command to start the Queue job
public final class QueuesCommand: AsyncCommand, Sendable {
    // See `Command.signature`.
    public let signature = Signature()
    
    // See `Command.Signature`.
    public struct Signature: CommandSignature {
        public init() {}
        
        @Option(name: "queue", help: "Specifies a single queue to run")
        var queue: String?
        
        @Flag(name: "scheduled", help: "Runs the scheduled queue jobs")
        var scheduled: Bool
    }
    
    // See `Command.help`.
    public var help: String { "Starts the Vapor Queues worker" }
    
    private let application: Application
    
    private let box: NIOLockedValueBox<Box>
    
    struct Box: Sendable {
        var jobTasks: [RepeatedTask]
        var scheduledTasks: [String: AnyScheduledJob.Task]
        var signalSources: [any DispatchSourceSignal]
        var didShutdown: Bool
    }
    
    /// Create a new ``QueuesCommand``.
    /// 
    /// - Parameters:
    ///   - application: The active Vapor `Application`.
    ///   - scheduled: This parameter is a historical artifact and has no effect.
    public init(application: Application, scheduled: Bool = false) {
        self.application = application
        self.box = .init(.init(jobTasks: [], scheduledTasks: [:], signalSources: [], didShutdown: false))
    }
    
    // See `AsyncCommand.run(using:signature:)`.
    public func run(using context: CommandContext, signature: QueuesCommand.Signature) async throws {
        // shutdown future
        let promise = self.application.eventLoopGroup.any().makePromise(of: Void.self)
        self.application.running = .start(using: promise)
        
        // setup signal sources for shutdown
        let signalQueue = DispatchQueue(label: "codes.vapor.jobs.command")
        func makeSignalSource(_ code: Int32) {
            #if canImport(Darwin)
            /// https://github.com/swift-server/swift-service-lifecycle/blob/main/Sources/UnixSignals/UnixSignalsSequence.swift#L77-L82
            signal(code, SIG_IGN)
            #endif
            
            let source = DispatchSource.makeSignalSource(signal: code, queue: signalQueue)
            source.setEventHandler {
                print() // clear ^C
                promise.succeed(())
            }
            source.resume()
            self.box.withLockedValue { $0.signalSources.append(source) }
        }
        makeSignalSource(SIGTERM)
        makeSignalSource(SIGINT)
        
        if signature.scheduled {
            self.application.logger.info("Starting scheduled jobs worker")
            try self.startScheduledJobs()
        } else {
            let queue: QueueName = signature.queue.map { .init(string: $0) } ?? .default
            
            self.application.logger.info("Starting jobs worker", metadata: ["queue": .string(queue.string)])
            try self.startJobs(on: queue)
        }
    }
    
    /// Starts an in-process jobs worker for queued tasks
    ///
    /// - Parameter queueName: The queue to run the jobs on
    public func startJobs(on queueName: QueueName) throws {
        let workerCount: Int
        switch self.application.queues.configuration.workerCount {
        case .default:
            workerCount = self.application.eventLoopGroup.makeIterator().reduce(0, { n, _ in n + 1 })
            self.application.logger.trace("Using default worker count", metadata: ["workerCount": "\(workerCount)"])
        case .custom(let custom):
            workerCount = custom
            self.application.logger.trace("Using custom worker count", metadata: ["workerCount": "\(workerCount)"])
        }

        var tasks: [RepeatedTask] = []
        for eventLoop in self.application.eventLoopGroup.makeIterator().prefix(workerCount) {
            self.application.logger.trace("Booting worker")

            let worker = self.application.queues.queue(queueName, on: eventLoop).worker
            let task = eventLoop.scheduleRepeatedAsyncTask(
                initialDelay: .zero,
                delay: worker.queue.configuration.refreshInterval
            ) { task in
                worker.queue.logger.trace("Running refresh task")
                return worker.run().map {
                    worker.queue.logger.trace("Worker ran the task successfully")
                }.recover { error in
                    worker.queue.logger.error("Job run failed", metadata: ["error": "\(String(reflecting: error))"])
                }.map {
                    if self.box.withLockedValue({ $0.didShutdown }) {
                        worker.queue.logger.trace("Shutting down, cancelling the task")
                        task.cancel()
                    }
                }
            }
            tasks.append(task)
        }

        self.box.withLockedValue { $0.jobTasks = tasks }
        self.application.logger.trace("Finished adding jobTasks, total count: \(tasks.count)")
    }
    
    /// Starts the scheduled jobs in-process
    public func startScheduledJobs() throws {
        self.application.logger.trace("Checking for scheduled jobs to begin the worker")

        guard !self.application.queues.configuration.scheduledJobs.isEmpty else {
            self.application.logger.warning("No scheduled jobs exist, exiting scheduled jobs worker.")
            return
        }

        self.application.logger.trace("Beginning the scheduling process")
        self.application.queues.configuration.scheduledJobs.forEach {
            self.application.logger.trace("Scheduling job", metadata: ["name": "\($0.job.name)"])
            self.schedule($0)
        }
    }
    
    private func schedule(_ job: AnyScheduledJob, after previousDate: Date? = nil) {
        self.box.withLockedValue { box in
            if box.didShutdown {
                self.application.logger.trace("Application is shutting down, not scheduling job", metadata: ["name": "\(job.job.name)"])
                return
            }

            let context = QueueContext(
                queueName: QueueName(string: "scheduled"),
                configuration: self.application.queues.configuration,
                application: self.application,
                logger: self.application.logger,
                on: self.application.eventLoopGroup.any()
            )

            guard let task = job.schedule(context: context, after: previousDate) else {
                return
            }

            self.application.logger.trace("Job was scheduled successfully", metadata: ["name": "\(job.job.name)"])
            box.scheduledTasks[job.job.name] = task

            // Capture the date this occurrence was scheduled for so we can pass it
            // to the next call.  This prevents a double-fire caused by timer jitter
            // (see AnyScheduledJob.schedule(context:after:) for details).
            let scheduledDate = task.scheduledDate
            task.done.whenComplete { result in
                switch result {
                case .failure(let error):
                    context.logger.error("Scheduled job failed", metadata: ["name": "\(job.job.name)", "error": "\(String(reflecting: error))"])
                case .success: break
                }
                // Explicitly spin the event loop so we don't deadlock on a reentrant call to this method.
                context.eventLoop.execute {
                    self.schedule(job, after: scheduledDate)
                }
            }
        }
    }
    
    /// Shuts down the jobs worker
    public func shutdown() {
        self.box.withLockedValue { box in
            box.didShutdown = true
        
            // stop running in case shutting down from signal
            self.application.running?.stop()
        
            // clear signal sources
            box.signalSources.forEach { $0.cancel() } // clear refs
            box.signalSources = []
        
            // stop all job queue workers
            box.jobTasks.forEach {
                $0.syncCancel(on: self.application.eventLoopGroup.any())
            }
            // stop all scheduled jobs
            box.scheduledTasks.values.forEach {
                $0.task.syncCancel(on: self.application.eventLoopGroup.any())
            }
        }
    }
    
    public func asyncShutdown() async {
        let (jobTasks, scheduledTasks) = self.box.withLockedValue { box in
            box.didShutdown = true
        
            // stop running in case shutting down from signal
            self.application.running?.stop()
            
            // clear signal sources
            box.signalSources.forEach { $0.cancel() } // clear refs
            box.signalSources = []
        
            // Release the lock before we start any suspensions
            return (box.jobTasks, box.scheduledTasks)
        }
        
        // stop all job queue workers
        for jobTask in jobTasks {
            await jobTask.asyncCancel(on: self.application.eventLoopGroup.any())
        }
        // stop all scheduled jobs
        for scheduledTask in scheduledTasks.values {
            await scheduledTask.task.asyncCancel(on: self.application.eventLoopGroup.any())
        }
    }
    
    deinit {
        assert(self.box.withLockedValue { $0.didShutdown }, "JobsCommand did not shutdown before deinit")
    }
}

