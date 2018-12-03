import Foundation
import Vapor

public struct JobsProvider: Provider {
    let refreshInterval: TimeAmount
    let persistenceLayer: JobsPersistenceLayer
    let persistenceKey: String
    
    public init(persistenceLayer: JobsPersistenceLayer,
                refreshInterval: TimeAmount = .seconds(1),
                persistenceKey: String = "vapor_jobs")
    {
        self.persistenceLayer = persistenceLayer
        self.refreshInterval = refreshInterval
        self.persistenceKey = persistenceKey
    }
    
    public func register(_ services: inout Services) throws {
        services.register { container -> QueueService in
            return QueueService(refreshInterval: self.refreshInterval,
                                persistenceLayer: self.persistenceLayer,
                                persistenceKey: self.persistenceKey,
                                container: container)
        }
    }
    
    public func didBoot(_ container: Container) throws -> EventLoopFuture<Void> {
        return container.future()
    }
}
