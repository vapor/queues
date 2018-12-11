import Foundation
import Vapor
import NIO
import NIOExtras

/// The command to start the Queue job
public struct JobsCommand: Command {
    
    /// See `Command`.`arguments`
    public var arguments: [CommandArgument] = []
    
    /// See `Command`.`options`
    public var options: [CommandOption] {
        return [
            CommandOption.value(name: "queue")
        ]
    }

    /// See `Command`.`help`
    public var help: [String] = ["Runs queued worker jobs"]
    
    /// Creates a new `JobCommand`
    public init() { }
    
    /// See `Command`.`run(using:)`
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        let elg = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let queueService = try context.container.make(QueueService.self)
        let jobContext = JobContext()
        let console = context.console
        let queue = QueueType(name: context.options["queue"] ?? QueueType.default.name)
        let key = queue.makeKey(with: queueService.persistenceKey)
        
        let quiesce = ServerQuiescingHelper(group: elg)
        let signalQueue = DispatchQueue(label: "vapor.jobs.command.SignalHandlingQueue")
        let signalSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: signalQueue)
        let fullyShutdownPromise: EventLoopPromise<Void> = elg.next().newPromise()
        signalSource.setEventHandler {
            print("SIGTERM RECEIVED")
            signalSource.cancel()
            quiesce.initiateShutdown(promise: fullyShutdownPromise)
        }
        signal(SIGTERM, SIG_IGN)
        signalSource.resume()
        
        var repeatedTasks: [RepeatedTask] = []
        for eventLoop in elg.makeIterator()! {
            let task = eventLoop.scheduleRepeatedTask(initialDelay: .seconds(0), delay: queueService.refreshInterval) { task -> EventLoopFuture<Void> in
                return queueService.persistenceLayer.get(key: key).flatMap { jobData in
                    //No job found, go to the next iteration
                    guard let jobData = jobData else { return eventLoop.future() }
                    let job = jobData.data
                    console.info("Dequeing Job", newLine: true)
                    
                    let futureJob = job.dequeue(context: jobContext, worker: elg)
                    return self.firstFutureToSucceed(future: futureJob, tries: jobData.maxRetryCount, on: elg)
                        .flatMap { _ in
                            guard let jobString = job.stringValue(key: key, maxRetryCount: jobData.maxRetryCount) else {
                                return eventLoop.future(error: Abort(.internalServerError))
                            }
                            
                            return queueService.persistenceLayer.completed(key: key, jobString: jobString)
                        }
                        .catchFlatMap { error in
                            console.error("Job error: \(error)", newLine: true)
                            return job.error(context: jobContext, error: error, worker: elg).transform(to: ())
                    }
                }
            }
            
            repeatedTasks.append(task)
        }
        
        return fullyShutdownPromise.futureResult.map { repeatedTasks.forEach { $0.cancel() } }
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
