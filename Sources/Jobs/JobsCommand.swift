import Vapor
import class NIOConcurrencyHelpers.Atomic
import class NIO.RepeatedTask

/// The command to start the Queue job
public final class JobsCommand: Command {
    /// See `Command.signature`
    public let signature = Signature()
    
    /// See `Command.Signature`
    public struct Signature: CommandSignature {
        public init() { }
        
        @Option(name: "queue", short: "Q", help: "Specifies a single queue to run")
        var queue: String?
        
        @Option(name: "scheduled", short: "S", help: "Runs the scheduled jobs")
        var scheduledJobs: Bool?
    }
    
    /// See `Command.help`
    public var help: String {
        return "Starts the Vapor Jobs worker"
    }
    
    private let application: Application
    private var jobTasks: [RepeatedTask]?
    private var scheduledWorkers: [ScheduledJobsWorker]?
    private let scheduled: Bool
    private var signalSources: [DispatchSourceSignal]
    private var didShutdown: Bool
    
    let isShuttingDown: Atomic<Bool>
    
    private var eventLoopGroup: EventLoopGroup {
        self.application.eventLoopGroup
    }

    /// Create a new `JobsCommand`
    init(application: Application, scheduled: Bool = false) {
        self.application = application
        self.scheduled = scheduled
        self.isShuttingDown = .init(value: false)
        self.signalSources = []
        self.didShutdown = false
    }

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
        
        if self.scheduled == true {
            context.console.info("Starting scheduled jobs worker")
            try self.startScheduledWorker()
        } else {
            let queue: JobsQueueName = signature.queue
                .flatMap { .init(string: $0) } ?? .default
            context.console.info("Starting jobs worker (queue: \(queue.string))")
            try self.startJobs(on: queue)
        }
    }
    
    private func startJobs(on queueName: JobsQueueName) throws {
        assert(self.jobTasks == nil)
        var tasks: [RepeatedTask] = []
        for eventLoop in eventLoopGroup.makeIterator() {
            let worker = self.application.jobs.worker(queueName: queueName, on: eventLoop)
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
            tasks.append(task)
        }
        self.jobTasks = tasks
    }
    
    private func startScheduledWorker() throws {
        var scheduledWorkers: [ScheduledJobsWorker] = []
        for eventLoop in eventLoopGroup.makeIterator() {
            let worker = self.application.jobs.scheduledWorker(on: eventLoop)
            try worker.start()
            scheduledWorkers.append(worker)
        }

        self.scheduledWorkers = scheduledWorkers
    }

    public func shutdown() {
        self.didShutdown = true
        
        // stop running in case shutting downf rom signal
        self.application.running?.stop()
        
        // clear signal sources
        self.signalSources.forEach { $0.cancel() } // clear refs
        self.signalSources = []
        
        // wait for all running tasks to finish
        var futures: [EventLoopFuture<Void>] = []
        if let tasks = self.jobTasks {
            tasks.forEach {
                let promise = self.eventLoopGroup.next().makePromise(of: Void.self)
                $0.cancel(promise: promise)
                futures.append(promise.futureResult)
            }
        }
        if let scheduledWorkers = scheduledWorkers {
            scheduledWorkers.forEach { worker in
                worker.shutdown()
            }
            futures += scheduledWorkers.map { $0.onShutdown }
        }
        try! EventLoopFuture<Void>
            .andAllComplete(futures, on: self.eventLoopGroup.next()).wait()
    }
    
    deinit {
        assert(self.didShutdown, "JobsCommand did not shutdown before deinit")
    }
}
