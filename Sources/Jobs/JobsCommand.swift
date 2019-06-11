import Foundation
import Vapor
import NIO

/// The command to start the Queue job
public final class JobsCommand: Command {
    
    /// See `Command.signature`
    public let signature = Signature()
    
    /// See `Command.Signature`
    public struct Signature: CommandSignature {
        let queue = Option<String>(name: "queue", type: .value)
    }
    
    /// See `Command.help`
    public var help: String = "Runs queued worker jobs"

    /// The registered `QueueService`
    public let queueService: QueueService
    
    /// The registered `JobContext`
    public let jobContext: JobContext
    
    /// The registered `JobsConfig`
    public let config: JobsConfig
    
    private var isShuttingDown: Bool {
        get {
            self._lock.lock()
            defer { self._lock.unlock() }
            return self._isShuttingDown
        }
        set {
            self._lock.lock()
            defer { self._lock.unlock() }
            self._isShuttingDown = newValue
        }
    }

    private var _isShuttingDown: Bool = false
    private var _lock: NSLock
    
    /// Creates a new `JobCommand`
    
    /// Creates a new `JobCommand`
    ///
    /// - Parameters:
    ///   - queueService: The registered `QueueService`
    ///   - jobContext: The registered `JobContext` object
    ///   - config: The registered `JobsConfig` object
    public init(queueService: QueueService, jobContext: JobContext, config: JobsConfig) {
        _lock = NSLock()
        
        self.queueService = queueService
        self.jobContext = jobContext
        self.config = config
    }
    
    /// See `Command`.`run(using:)`
    public func run(using context: CommandContext<JobsCommand>) throws {
        context.console.info("Starting Jobs worker")
        let queueName = context.option(\.queue) ?? QueueName.default.name
        let elg = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let signalQueue = DispatchQueue(label: "vapor.jobs.command.SignalHandlingQueue")
        
        //SIGTERM
        let termSignalSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: signalQueue)
        termSignalSource.setEventHandler {
            print("Shutting down remaining jobs.")
            self.isShuttingDown = true
            termSignalSource.cancel()
        }
        signal(SIGTERM, SIG_IGN)
        termSignalSource.resume()
        
        //SIGINT
        let intSignalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: signalQueue)
        intSignalSource.setEventHandler {
            print("Shutting down remaining jobs.")
            self.isShuttingDown = true
            intSignalSource.cancel()
        }
        signal(SIGINT, SIG_IGN)
        intSignalSource.resume()
        
        
        var shutdownPromises: [EventLoopPromise<Void>] = []
        for eventLoop in elg.makeIterator() {
            let console = context.console
            let shutdownPromise: EventLoopPromise<Void> = eventLoop.makePromise()
            
            shutdownPromises.append(shutdownPromise)
            
            eventLoop.submit {
                try self.setupTask(eventLoop: eventLoop,
                                   queueName: queueName,
                                   console: console,
                                   promise: shutdownPromise)
            }.whenFailure {
                console.error("Could not boot EventLoop: \($0)")
            }
        }
        
        try EventLoopFuture.andAllComplete(shutdownPromises.map { $0.futureResult }, on: elg.next()).wait()
    }
    
    private func setupTask(
        eventLoop: EventLoop,
        queueName: String,
        console: ConsoleKit.Console,
		promise: EventLoopPromise<Void>
    ) throws {
        let queue = QueueName(name: queueName)
        let key = queue.makeKey(with: queueService.persistenceKey)
        _ = eventLoop.scheduleRepeatedAsyncTask(initialDelay: .seconds(0), delay: queueService.refreshInterval) { task -> EventLoopFuture<Void> in
            //Check if shutting down

            if self.isShuttingDown {
                task.cancel()
                promise.succeed(())
            }

            return self.queueService.persistenceLayer.get(key: key).flatMap { jobStorage in
                //No job found, go to the next iteration
                guard let jobStorage = jobStorage else { return eventLoop.makeSucceededFuture(()) }
                guard let job = self.config.make(for: jobStorage.jobName) else {
                    return eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Please register \(jobStorage.jobName)"))
                }

                console.info("Dequeing Job job_id=[\(jobStorage.id)]", newLine: true)

                let jobRunPromise = eventLoop.makePromise(of: Void.self)

                let futureJob = job.anyDequeue(self.jobContext, jobStorage)
                self.firstFutureToSucceed(future: futureJob, tries: jobStorage.maxRetryCount, on: eventLoop).flatMapError { error in
                    console.error("Error: \(error) job_id=[\(jobStorage.id)]", newLine: true)
                    return job.error(self.jobContext, error, jobStorage)
                }.whenComplete { _ in
                    self.queueService.persistenceLayer.completed(key: key, jobStorage: jobStorage).cascade(to: jobRunPromise)
                }

                return jobRunPromise.futureResult
            }
        }
    }
    
    /// Returns the first time a given future succeeds and is under the `tries`
    ///
    /// - Parameters:
    ///   - future: The future to run recursively
    ///   - tries: The number of tries to execute this future before returning a failure
    ///   - worker: An `EventLoopGroup` that can be used to generate future values
    /// - Returns: The completed future, with or without an error
    private func firstFutureToSucceed<T>(future: EventLoopFuture<T>, tries: Int, on worker: EventLoopGroup) -> EventLoopFuture<T> {
        return future.map { complete in
            return complete
        }.flatMapError { error in
            if tries == 0 {
                return worker.next().makeFailedFuture(error)
            } else {
                return self.firstFutureToSucceed(future: future, tries: tries - 1, on: worker)
            }
        }
    }
}
