import Foundation
import Vapor
import Redis

public struct QueueService: Service {
    let refreshInterval: TimeAmount
    let redisClient: RedisClient
    
    public func run(job: Job, retryCount: Int? = nil) -> EventLoopFuture<Void> {
        return redisClient.future()
    }
}
