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
        
        _ = eventLoop.scheduleRepeatedTask(
            initialDelay: .seconds(0),
            delay: queueService.refreshInterval
        ) { task -> EventLoopFuture<Void> in
            //Check if shutting down
            
            if self.isShuttingDown {
                task.cancel()
                promise.succeed()
            }
            
            return queueService.persistenceLayer.get(key: key).flatMap { jobStorage in
                //No job found, go to the next iteration
                guard let jobStorage = jobStorage else { return eventLoop.future() }

                // If the job has a delay, we must check to make sure we can execute
                if let delay = jobStorage.delayUntil {
                    guard delay >= Date() else {
                        // The delay has not passed yet, requeue the job
                        return queueService.persistenceLayer.requeue(key: key, jobStorage: jobStorage)
                    }
                }

                guard let job = config.make(for: jobStorage.jobName) else {
                    return eventLoop.future(error: Abort(.internalServerError, reason: "Please register \(jobStorage.jobName)"))
                }
                
                console.info("Dequeing Job job_id=[\(jobStorage.id)]", newLine: true)
                
                let jobRunPromise = eventLoop.newPromise(Void.self)
                self.firstJobToSucceed(job: job,
                                       jobContext: jobContext,
                                       jobStorage: jobStorage,
                                       tries: jobStorage.maxRetryCount,
                                       on: eventLoop)
                .catchFlatMap { error in
                    console.error("Error: \(error) job_id=[\(jobStorage.id)]", newLine: true)
                    return job.error(jobContext, error, jobStorage)
                }.always {
                    queueService.persistenceLayer.completed(key: key, jobStorage: jobStorage).cascade(promise: jobRunPromise)
                }
                
                return jobRunPromise.futureResult
            }
        }
    }
    
    private func firstJobToSucceed(job: AnyJob,
                                   jobContext: JobContext,
                                   jobStorage: JobStorage,
                                   tries: Int,
                                   on worker: EventLoopGroup) -> Future<Void>
    {
        
        let futureJob = job.anyDequeue(jobContext, jobStorage)
        return futureJob.map { complete in
            return complete
        }.catchFlatMap { error in
            if tries == 0 {
                return worker.future(error: error)
            } else {
                return self.firstJobToSucceed(job: job, jobContext: jobContext, jobStorage: jobStorage, tries: tries - 1, on: worker)
            }
        }
    }
}
