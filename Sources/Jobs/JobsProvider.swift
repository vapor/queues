import Foundation
import Vapor
import Redis

public struct JobsProvider: Provider {
    let refreshInterval: TimeAmount
    let persistenceLayer: PersistenceLayer
    let persistenceKey: String
    let jobContext: JobContext
    
    public init(persistenceLayer: PersistenceLayer,
                refreshInterval: TimeAmount = .seconds(1),
                persistenceKey: String = "vapor_jobs",
                jobContext: JobContext)
    {
        self.persistenceLayer = persistenceLayer
        self.refreshInterval = refreshInterval
        self.persistenceKey = persistenceKey
        self.jobContext = jobContext
    }
    
    public func register(_ services: inout Services) throws {
        services.register { container -> QueueService in
            return QueueService(refreshInterval: self.refreshInterval,
                                persistenceLayer: self.persistenceLayer,
                                persistenceKey: self.persistenceKey,
                                jobContext: self.jobContext,
                                container: container)
        }
    }
    
    public func didBoot(_ container: Container) throws -> EventLoopFuture<Void> {
        return container.future()
    }
}
