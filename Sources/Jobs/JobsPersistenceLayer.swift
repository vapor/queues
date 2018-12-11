import Foundation
import NIO
import Redis

public protocol JobsPersistenceLayer {
    func get(key: String, worker: EventLoopGroup) -> EventLoopFuture<JobData?>
    func set<J: Job>(key: String, job: J, maxRetryCount: Int, worker: EventLoopGroup) -> EventLoopFuture<Void>
    func completed(key: String, jobString: String, worker: EventLoopGroup) -> EventLoopFuture<Void>
}

//TODO: - Move this into a separate redis package
extension RedisDatabase: JobsPersistenceLayer {
    public func set<J: Job>(key: String, job: J, maxRetryCount: Int, worker: EventLoopGroup) -> EventLoopFuture<Void> {
        return self.newConnection(on: worker).flatMap(to: RedisClient.self) { conn in
            let jobData = JobData(key: key, data: job, maxRetryCount: maxRetryCount)
            let data = try JSONEncoder().encode(jobData).convertToRedisData()
            return conn.lpush([data], into: key).transform(to: conn)
        }.map { conn in
            return conn.close()
        }
    }
    
    public func get(key: String, worker: EventLoopGroup) -> EventLoopFuture<JobData?> {
        let processingKey = key + "-processing"
        
        return self.newConnection(on: worker).flatMap { conn in
            return conn.rpoplpush(source: key, destination: processingKey).transform(to: conn)
        }.flatMap { conn in
            return conn.command("LPOP", [try processingKey.convertToRedisData()]).and(result: conn)
        }.map { redisData, conn in
            conn.close()
            guard let data = redisData.data else { return nil }
            return try? JSONDecoder().decode(JobData.self, from: data)
        }
    }
    
    public func completed(key: String, jobString: String, worker: EventLoopGroup) -> EventLoopFuture<Void> {
        return worker.future()
    }
}
