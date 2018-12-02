import Foundation
import Vapor
import Redis

public struct JobsProvider: Provider {
    let refreshInterval: TimeAmount
    let redisClient: RedisClient
    let persistenceKey: String
    
    public init(redisClient: RedisClient, refreshInterval: TimeAmount = .seconds(1), persistenceKey: String = "vapor_jobs") {
        self.redisClient = redisClient
        self.refreshInterval = refreshInterval
        self.persistenceKey = persistenceKey
    }
    
    public func register(_ services: inout Services) throws {
        services.register { container -> QueueService in
            return QueueService(refreshInterval: self.refreshInterval, redisClient: self.redisClient, persistenceKey: self.persistenceKey)
        }
    }
    
    public func didBoot(_ container: Container) throws -> EventLoopFuture<Void> {
        return container.future()
    }
}
