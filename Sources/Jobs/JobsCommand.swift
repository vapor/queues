import Foundation
import Vapor

public struct JobsCommand: Command {
    public var arguments: [CommandArgument] = []
    public var options: [CommandOption] = []
    public var help: [String] = ["TODO"]
    
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        let container = context.container
        let eventLoop = container.eventLoop
        
        let queueService = try container.make(QueueService.self)
        let redisClient = queueService.redisClient
        let promise = eventLoop.newPromise(Void.self)
        
        let _ = eventLoop.scheduleRepeatedTask(initialDelay: .seconds(0), delay: queueService.refreshInterval) { task -> EventLoopFuture<Void> in
            return try redisClient.get(Constants.persistenceKey, as: Job.self).map(to: Void.self) { jobs in
                
            }
        }
        
        return promise.futureResult
    }
}
