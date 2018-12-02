import Foundation
import Vapor
import Redis

public struct JobsProvider: Provider {
    let refreshInterval: TimeAmount
    let redisClient: RedisClient
    
    public init(redisClient: RedisClient, refreshInterval: TimeAmount = .seconds(1)) {
        self.redisClient = redisClient
        self.refreshInterval = refreshInterval
    }
    
    public func register(_ services: inout Services) throws {
        services.register { container -> QueueService in
            return QueueService(refreshInterval: self.refreshInterval, redisClient: self.redisClient)
        }
    }
    
    public func didBoot(_ container: Container) throws -> EventLoopFuture<Void> {
        return container.future()
    }
}
