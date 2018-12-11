import Foundation
import Vapor

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
        let container = context.container
        let eventLoop = container.eventLoop
        
        let queueService = try container.make(QueueService.self)
        let promise = eventLoop.newPromise(Void.self)
        let jobContext = JobContext()
        let console = context.console
        let queue = QueueType(name: context.options["queue"] ?? QueueType.default.name)
        
        let key = queue.makeKey(with: queueService.persistenceKey)
        _ = eventLoop.scheduleRepeatedTask(initialDelay: .seconds(0), delay: queueService.refreshInterval) { task -> EventLoopFuture<Void> in
            return queueService.persistenceLayer.get(key: key, worker: container).flatMap { jobData in
                //No job found, go to the next iteration
                guard let jobData = jobData else { return container.future() }
                let job = jobData.data
                console.info("Dequeing Job", newLine: true)
                
                let futureJob = job.dequeue(context: jobContext, worker: container)
                return self.firstFutureToSucceed(future: futureJob, tries: jobData.maxRetryCount, on: container)
                    .flatMap { _ in
                        guard let jobString = job.stringValue(key: key, maxRetryCount: jobData.maxRetryCount) else {
                            return container.future(error: Abort(.internalServerError))
                        }
                        
                        return queueService.persistenceLayer.completed(key: key, jobString: jobString, worker: container)
                    }
                    .catchFlatMap { error in
                        console.error("Job error: \(error)", newLine: true)
                        return job.error(context: jobContext, error: error, worker: container).transform(to: ())
                }
            }
        }
        
        return promise.futureResult
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
