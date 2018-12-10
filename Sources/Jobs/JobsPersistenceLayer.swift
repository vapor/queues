import Foundation
import NIO
import Redis

public protocol JobsPersistenceLayer {
    func get(key: String, worker: EventLoopGroup) -> EventLoopFuture<Job?>
    func set<J: Job>(key: String, job: J, worker: EventLoopGroup) throws -> EventLoopFuture<Void>
    func completed(key: String, jobString: String, worker: EventLoopGroup) throws -> EventLoopFuture<Void>
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
    
    public func get(key: String, worker: EventLoopGroup) -> EventLoopFuture<Job?> {
        return self.newConnection(on: worker).flatMap { conn in
            return conn.rpoplpush(source: key, destination: key + "-processing").and(result: conn)
        }.map { redisData, conn in
            conn.close()
            guard let data = redisData.data else { return nil }
            guard let jobData = try? JSONDecoder().decode(JobData.self, from: data) else { return nil }
            return jobData.data
        }
    }
    
    public func completed(key: String, jobString: String, worker: EventLoopGroup) throws -> EventLoopFuture<Void> {
        return self.newConnection(on: worker).flatMap(to: RedisClient.self) { conn in
            let argumentKey = try "\(key)-processing".convertToRedisData()
            let count = try (-1).convertToRedisData()
            let value = try jobString.convertToRedisData()
            
            return conn.command("LREM", [argumentKey, count, value]).transform(to: conn)
        }.map { conn in
            conn.close()
        }
    }
}
