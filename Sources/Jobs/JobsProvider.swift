import Foundation
import Vapor

/// A provider used to setup the `Jobs` package
public struct JobsProvider: Provider {
    
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
    
    
    /// See `Provider`.`register(_ services:)`
    public func register(_ services: inout Services) throws {
        services.register { container -> QueueService in
            let persistenceLayer = try container.make(JobsPersistenceLayer.self)
            
            return QueueService(refreshInterval: self.refreshInterval,
                                persistenceLayer: persistenceLayer,
                                persistenceKey: self.persistenceKey)
        }
    }
    
    
    /// See `Provider`.`didBoot(_ container:)`
    public func didBoot(_ container: Container) throws -> EventLoopFuture<Void> {
        return container.future()
    }
}
