import Foundation
import NIO
import Redis

public protocol JobsPersistenceLayer {
    func get(key: String) throws -> EventLoopFuture<[Job]>
    func set(key: String, jobs: [Job]) throws -> EventLoopFuture<Void>
}

extension RedisClient: JobsPersistenceLayer {
    public func get(key: String) throws -> EventLoopFuture<[Job]> {
        return self.future([])
    }
    
    public func set(key: String, jobs: [Job]) throws -> EventLoopFuture<Void> {
        return self.future()
    }
}
