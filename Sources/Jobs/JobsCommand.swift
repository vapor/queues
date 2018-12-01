import Foundation
import Vapor

public struct JobsCommand: Command {
    public var arguments: [CommandArgument] = []
    public var options: [CommandOption] = []
    public var help: [String] = ["TODO"]
    
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        let eventLoop = context.container.eventLoop
        let _ = eventLoop.scheduleRepeatedTask(initialDelay: .seconds(0), delay: .seconds(1)) { task -> EventLoopFuture<Void> in
            //TODO: - execute the jobs here
            
            return eventLoop.future()
        }
        
        return context.container.future()
    }
}
