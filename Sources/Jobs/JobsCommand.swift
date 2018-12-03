import Foundation
import Vapor

public struct JobsCommand: Command {
    public var arguments: [CommandArgument] = []
    public var options: [CommandOption] = []
    public var help: [String] = ["Runs queued worker jobs"]
    
    public init() { }
    
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        let container = context.container
        let eventLoop = container.eventLoop
        
        let queueService = try container.make(QueueService.self)
        let promise = eventLoop.newPromise(Void.self)
        let jobContext = JobContext()
        
        _ = eventLoop.scheduleRepeatedTask(initialDelay: .seconds(0), delay: queueService.refreshInterval) { task -> EventLoopFuture<Void> in
            do {
                return try queueService.persistenceLayer.get(key: queueService.persistenceKey, worker: container).flatMap { job in
                    return try job
                        .dequeue(context: jobContext, worker: container)
                        .transform(to: ())
                        .catchFlatMap { error in
                            return job.error(context: jobContext, error: error, worker: container).transform(to: ())
                    }
                }
            } catch {
                //handle error somehow
            }
            
            return container.future()
        }
        
        return promise.futureResult
    }
}
