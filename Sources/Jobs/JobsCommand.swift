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
        
        let _ = eventLoop.scheduleRepeatedTask(initialDelay: .seconds(0), delay: queueService.refreshInterval) { task -> EventLoopFuture<Void> in
            //TODO: - execute the jobs here
            
            return container.future()
        }
        
        return container.future()
    }
}
