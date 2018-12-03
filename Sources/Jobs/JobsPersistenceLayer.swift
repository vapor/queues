import Foundation
import NIO
import Redis

public protocol JobsPersistenceLayer {
    func get(key: String) throws -> EventLoopFuture<Job>
    func set<J: Job>(key: String, job: J) throws -> EventLoopFuture<Void>
}

extension RedisClient: JobsPersistenceLayer {
    public func set<J: Job>(key: String, job: J) throws -> EventLoopFuture<Void> {
        let jobData = JobData(key: key, data: job)
        let data = try JSONEncoder().encode(jobData).convertToRedisData()
        return lpush([data], into: key).transform(to: ())
    }
    
    public func get(key: String) throws  -> EventLoopFuture<Job> {
        return rPop(key).map { redisData in
            guard let data = redisData.data else { throw JobError.cannotConvertData }
            let jobData = try JSONDecoder().decode(JobData.self, from: data)
            return jobData.data
        }
    }
}

struct TestingRedisJob: Job {
    let maxRetryCount = 0
    
    func dequeue(context: JobContext, worker: EventLoopGroup) throws -> EventLoopFuture<Void> {
        return worker.future()
    }
}
