import Foundation
import NIO

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
