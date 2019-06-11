import Foundation
import Vapor
import NIO

/// A provider used to setup the `Jobs` package
public struct JobsProvider: Provider {
    
    /// See `Provider`.`register(_ services:)`
    public func register(_ s: inout Services) {
        s.register(
            QueueService.self
        ) { container -> QueueService in
            let persistenceLayer = try container.make(JobsPersistenceLayer.self)
            
            return QueueService(refreshInterval: self.refreshInterval,
                                persistenceLayer: persistenceLayer,
                                persistenceKey: self.persistenceKey)
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
