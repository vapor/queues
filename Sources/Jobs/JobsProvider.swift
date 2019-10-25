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
        app.register(JobsService.self) { app in
            return ApplicationJobsService(
                configuration: app.make(),
                driver: app.make(),
                logger: app.make(),
                eventLoopPreference: .indifferent
            )
        }

        app.register(JobsConfiguration.self) { _ in
            return JobsConfiguration()
        }

        app.register(JobsCommand.self) { app in
            return .init(application: app)
        }
        
        app.register(extension: CommandConfiguration.self) { configuration, a in
            configuration.use(a.make(JobsCommand.self), as: self.commandKey)
        }
    }
}
