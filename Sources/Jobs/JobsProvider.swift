import Foundation
import Vapor
import NIO

/// A provider used to setup the `Jobs` package
public struct JobsProvider: Provider {
    /// The key to use for calling the command. Defaults to `jobs`
    public var commandKey: String
    
    /// Initializes the `Jobs` package
    public init(commandKey: String = "jobs") {
        self.commandKey = commandKey
    }

    /// See `Provider`.`register(_ app:)`
    public func register(_ app: Application) {
        app.register(JobsService.self) { a in
            return JobsService(configuration: a.make(), driver: a.make())
        }

        app.register(JobsConfiguration.self) { _ in
            return JobsConfiguration()
        }

        app.register(JobsCommand.self) { a in
            return .init(application: a.make())
        }
        
        app.register(JobsWorker.self) { a in
            return .init(
                configuration: a.make(),
                driver: a.make(),
                context: a.make(),
                logger: a.make(),
                on: a.make()
            )
        }
        
        app.register(ScheduledJobsWorker.self) { a in
            return .init(
                configuration: a.make(),
                context: a.make(),
                logger: a.make(),
                on: a.make()
            )
        }
        
        app.register(JobContext.self) { a in
            return .init(eventLoopGroup: a.make(), preference: .indifferent)
        }
        
        app.register(extension: CommandConfiguration.self) { configuration, a in
            configuration.use(a.make(JobsCommand.self), as: self.commandKey)
        }
    }
}
