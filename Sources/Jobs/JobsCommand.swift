import Foundation
import Vapor
import NIO

/// The command to start the Queue job
public class JobsCommand: Command {
    
    /// See `Command`.`arguments`
    public var arguments: [CommandArgument] = []
    
    /// See `Command`.`options`
    public var options: [CommandOption] {
        return [
            CommandOption.value(name: "queue")
        ]
    }
    
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
    
    /// See `Command`.`help`
    public var help: [String] = ["Runs queued worker jobs"]
    
    /// Creates a new `JobCommand`
    public init() {
        _lock = NSLock()
    }
    
    /// See `Command`.`run(using:)`
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        context.console.info("Starting Jobs worker")

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
        for eventLoop in elg.makeIterator()! {
            let sub = context.container.subContainer(on: eventLoop)
            let console = context.console
            let queueName = context.options["queue"] ?? QueueName.default.name
            let shutdownPromise: EventLoopPromise<Void> = eventLoop.newPromise()
            
            shutdownPromises.append(shutdownPromise)
            
            eventLoop.submit {
                try self.setupTask(eventLoop: eventLoop,
                                   container: sub,
                                   queueName: queueName,
                                   console: console,
                                   promise: shutdownPromise)
            }.catch {
                console.error("Could not boot EventLoop: \($0)")
            }
        }
        
        return .andAll(shutdownPromises.map { $0.futureResult }, eventLoop: elg.next())
    }
    
    private func setupTask(eventLoop: EventLoop,
                           container: SubContainer,
                           queueName: String,
                           console: Console,
                           promise: EventLoopPromise<Void>) throws
    {
        let queue = QueueName(name: queueName)
        let queueService = try container.make(QueueService.self)
        let jobContext = try container.make(JobContext.self)
        let key = queue.makeKey(with: queueService.persistenceKey)
        let config = try container.make(JobsConfig.self)
        
        _ = eventLoop.scheduleRepeatedTask(initialDelay: .seconds(0), delay: queueService.refreshInterval) { task -> EventLoopFuture<Void> in
            return queueService.persistenceLayer.get(key: key).flatMap { jobStorage in
                //Check if shutting down
                
                if self.isShuttingDown {
                    task.cancel()
                    promise.succeed()
                }
                
                //No job found, go to the next iteration
                guard let jobStorage = jobStorage else { return eventLoop.future() }
                guard let job = config.make(for: jobStorage.jobName) else {
                    return eventLoop.future(error: Abort(.internalServerError, reason: "Please register \(jobStorage.jobName)"))
                }
                
                console.info("Dequeing Job job_id=[\(jobStorage.id)]", newLine: true)
                
                let futureJob = job.anyDequeue(jobContext, jobStorage)
                return self.firstFutureToSucceed(future: futureJob, tries: jobStorage.maxRetryCount, on: eventLoop).flatMap { _ in
                    return queueService.persistenceLayer.completed(key: key, jobStorage: jobStorage)
                }.catchFlatMap { error in
                    console.error("Error: \(error) job_id=[\(jobStorage.id)]", newLine: true)
                    
                    return queueService
                        .persistenceLayer
                        .completed(key: key, jobStorage: jobStorage)
                        .flatMap { _ in
                            return job.error(jobContext, error, jobStorage)
                    }
                }
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
    private func firstFutureToSucceed<T>(future: Future<T>, tries: Int, on worker: EventLoopGroup) -> Future<T> {
        return future.map { complete in
            return complete
        }.catchFlatMap { error in
            if tries == 0 {
                return worker.future(error: error)
            } else {
                return self.firstFutureToSucceed(future: future, tries: tries - 1, on: worker)
            }
        }
    }
}
