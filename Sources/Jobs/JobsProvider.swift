import Foundation
import Vapor

/// A provider used to setup the `Jobs` package
public struct JobsProvider: Provider {
    
    /// The amount of time the queue should wait in between each completed job
    let refreshInterval: TimeAmount
    
    /// The persistence layer that should be used to store the jobs
    let persistenceLayer: JobsPersistenceLayer
    
    /// The base key that should be used in the persistence layer
    let persistenceKey: String
    
    
    /// Initializes the `Jobs` package
    ///
    /// - Parameters:
    ///   - persistenceLayer: The persistence layer that should be used to store the jobs
    ///   - refreshInterval: The amount of time the queue should wait in between each completed job
    ///   - persistenceKey: The base key that should be used in the persistence layer
    public init(persistenceLayer: JobsPersistenceLayer,
                refreshInterval: TimeAmount = .seconds(1),
                persistenceKey: String = "vapor_jobs")
    {
        self.persistenceLayer = persistenceLayer
        self.refreshInterval = refreshInterval
        self.persistenceKey = persistenceKey
    }
    
    
    /// See `Provider`.`register(_ services:)`
    public func register(_ services: inout Services) throws {
        services.register { container -> QueueService in
            return QueueService(refreshInterval: self.refreshInterval,
                                persistenceLayer: self.persistenceLayer,
                                persistenceKey: self.persistenceKey,
                                worker: container)
        }
    }
    
    
    /// See `Provider`.`didBoot(_ container:)`
    public func didBoot(_ container: Container) throws -> EventLoopFuture<Void> {
        return container.future()
    }
}
