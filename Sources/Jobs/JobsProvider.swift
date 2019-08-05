import Foundation
import Vapor
import NIO

/// A provider used to setup the `Jobs` package
public struct JobsProvider: Provider {
    /// The number of seconds to wait before checking for the next job. Defaults to `1`
    public var refreshInterval: TimeAmount
    
    /// The key that stores the data about a job. Defaults to `vapor_jobs`
    public var persistenceKey: String
    
    /// The key to use for calling the command. Defaults to `jobs`
    public var commandKey: String
    
    /// Initializes the `Jobs` package
    public init(
        refreshInterval: TimeAmount = .seconds(1),
        persistenceKey: String = "vapor_jobs",
        commandKey: String = "jobs"
    ) {
        self.refreshInterval = refreshInterval
        self.persistenceKey = persistenceKey
        self.commandKey = commandKey
    }

    /// See `Provider`.`register(_ services:)`
    public func register(_ s: inout Services) {
        s.register(JobsService.self) { c in
            return try JobsService(configuration: c.make(), driver: c.make())
        }

        s.register(JobsConfiguration.self) { container in
            return JobsConfiguration(
                refreshInterval: self.refreshInterval,
                persistenceKey: self.persistenceKey
            )
        }

        s.register(JobsCommand.self) { c in
            return try .init(application: c.make())
        }
        
        s.register(JobsWorker.self) { c in
            return try .init(
                configuration: c.make(),
                driver: c.make(),
                context: c.make(),
                logger: c.make(),
                on: c.eventLoop
            )
        }
        
        s.register(ScheduledJobsWorker.self) { c in
            return try .init(
                configuration: c.make(),
                context: c.make(),
                logger: c.make(),
                on: c.eventLoop
            )
        }

        s.register(JobContext.self) { c in
            return .init(eventLoop: c.eventLoop)
        }

        s.extend(CommandConfiguration.self) { configuration, c in
            try configuration.use(c.make(JobsCommand.self), as: self.commandKey)
        }
    }
}
