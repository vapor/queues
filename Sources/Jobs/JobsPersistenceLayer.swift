import Foundation
import NIO
import Redis

public protocol JobsPersistenceLayer {
    func get(key: String, worker: EventLoopGroup) throws -> EventLoopFuture<Job>
    func set<J: Job>(key: String, job: J, worker: EventLoopGroup) throws -> EventLoopFuture<Void>
}

//TODO: - Move this into a separate redis package
extension RedisDatabase: JobsPersistenceLayer {
    public func set<J: Job>(key: String, job: J, worker: EventLoopGroup) throws -> EventLoopFuture<Void> {
        return self.newConnection(on: worker).flatMap(to: RedisClient.self) { conn in
            let jobData = JobData(key: key, data: job)
            let data = try JSONEncoder().encode(jobData).convertToRedisData()
            return conn.lpush([data], into: key).transform(to: conn)
        }.map { conn in
            return conn.close()
        }
    }
    
    public func get(key: String, worker: EventLoopGroup) throws  -> EventLoopFuture<Job> {
        return self.newConnection(on: worker).flatMap { conn in
            return conn.rPop(key).and(result: conn)
        }.map { redisData, conn in
            conn.close()
            guard let data = redisData.data else { throw JobError.cannotConvertData }
            let jobData = try JSONDecoder().decode(JobData.self, from: data)
            return jobData.data
        }
    }
}
