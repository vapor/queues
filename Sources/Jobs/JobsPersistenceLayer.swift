import Foundation
import NIO
import Redis

/// A type that can store and retrieve jobs from a persistence layer
public protocol JobsPersistenceLayer {
    
    /// Returns a `JobData` wrapper for a specified key.
    ///
    /// - Parameters:
    ///   - key: The key that the data is stored under.
    ///   - worker: An `EventLoopGroup` that can be used to generate future values
    /// - Returns: The retrieved `JobData`, if it exists.
    func get(key: String, worker: EventLoopGroup) -> EventLoopFuture<JobData?>
    
    /// Handles adding a `Job` to the persistence layer for future processing.
    ///
    /// - Parameters:
    ///   - key: The key to add the `Job` under.
    ///   - job: The `Job` to add.
    ///   - maxRetryCount: Maximum number of times this job should be retried before failing.
    ///   - worker: An `EventLoopGroup` that can be used to generate future values
    /// - Returns: A future `Void` value used to signify completion
    func set<J: Job>(key: String, job: J, maxRetryCount: Int, worker: EventLoopGroup) -> EventLoopFuture<Void>
    
    /// Called upon successful completion of the `Job`. Should be used for cleanup.
    ///
    /// - Parameters:
    ///   - key: The key that the `Job` was stored under
    ///   - jobString: A string representation of the `Job`
    ///   - worker: An `EventLoopGroup` that can be used to generate future values
    /// - Returns: A future `Void` value used to signify completion
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
