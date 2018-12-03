import Foundation
import NIO
import Redis

public protocol JobsPersistenceLayer {
    func getNext(key: String) -> EventLoopFuture<Job>
    func set(key: String, jobs: [Job]) -> EventLoopFuture<Void>
}

extension RedisClient: JobsPersistenceLayer {
    public func getNext(key: String) -> EventLoopFuture<Job> {
        return self.future(TestingRedisJob())
    }
    
    public func set(key: String, jobs: [Job]) -> EventLoopFuture<Void> {
        return self.future()
    }
}

struct TestingRedisJob: Job {
    func dequeue(context: JobContext, worker: EventLoopGroup) throws -> EventLoopFuture<Void> {
        return worker.future()
    }
}
