import Foundation
import Vapor

public struct JobsCommand: Command {
    public var arguments: [CommandArgument] = []
    public var options: [CommandOption] = []
    public var help: [String] = ["Runs queued worker jobs"]
    
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        let container = context.container
        let eventLoop = container.eventLoop
        
        let queueService = try container.make(QueueService.self)
        let promise = eventLoop.newPromise(Void.self)
        let jobContext = JobContext()
        
        _ = eventLoop.scheduleRepeatedTask(initialDelay: .seconds(0), delay: queueService.refreshInterval) { task -> EventLoopFuture<Void> in
            return queueService.persistenceLayer.getNext(key: queueService.persistenceKey).flatMap { job in
                return try job
                    .dequeue(context: jobContext, worker: container)
                    .transform(to: ())
                .catchFlatMap { error in
                    return job.error(context: jobContext, error: error, worker: container).transform(to: ())
                }
            }
        }
        
        return promise.futureResult
    }
}
