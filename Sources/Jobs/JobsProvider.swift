import Foundation
import Vapor
import NIO

/// A provider used to setup the `Jobs` package
public struct JobsProvider: Provider {
    /// See `Provider`.`register(_ services:)`
    public func register(_ s: inout Services) {
        s.register(QueueService.self) { container in
            return try QueueService(
                refreshInterval: self.refreshInterval,
                persistenceLayer: container.make(JobsPersistenceLayer.self),
                persistenceKey: self.persistenceKey
            )
        }

        s.register(JobsConfiguration.self) { container in
            return JobsConfiguration()
        }

        s.register(JobsCommand.self) { c in
            return try .init(
                queueService: c.make(),
                jobContext: c.make(),
                configuration: c.make()
            )
        }

        s.register(JobContext.self) { c in
            return .init(eventLoop: c.eventLoop)
        }

        s.extend(CommandConfiguration.self) { configuration, c in
            try configuration.use(c.make(JobsCommand.self), as: "jobs")
        }
    }
    
    /// The amount of time the queue should wait in between each completed job
    let refreshInterval: TimeAmount
    
    /// The base key that should be used in the persistence layer
    let persistenceKey: String
    
    
    /// Initializes the `Jobs` package
    ///
    /// - Parameters:
    ///   - refreshInterval: The amount of time the queue should wait in between each completed job
    ///   - persistenceKey: The base key that should be used in the persistence layer
    public init(refreshInterval: TimeAmount = .seconds(1),
                persistenceKey: String = "vapor_jobs")
    {
        self.refreshInterval = refreshInterval
        self.persistenceKey = persistenceKey
    }
}
