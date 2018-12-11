import Foundation
import NIO

/// A type that can store and retrieve jobs from a persistence layer
public protocol JobsPersistenceLayer {
    
    /// The event loop to be run on
    var eventLoop: EventLoop { get set }
    
    /// Returns a `JobData` wrapper for a specified key.
    ///
    /// - Parameters:
    ///   - key: The key that the data is stored under.
    ///   - jobsConfig: The `JobsConfig` registered via services
    /// - Returns: The retrieved `JobData`, if it exists.
    func get(key: String, jobsConfig: JobsConfig) -> EventLoopFuture<JobData?>
    
    /// Handles adding a `Job` to the persistence layer for future processing.
    ///
    /// - Parameters:
    ///   - key: The key to add the `Job` under.
    ///   - job: The `Job` to add.
    ///   - maxRetryCount: Maximum number of times this job should be retried before failing.
    /// - Returns: A future `Void` value used to signify completion
    func set<J: Job>(key: String, job: J, maxRetryCount: Int) -> EventLoopFuture<Void>
    
    /// Called upon successful completion of the `Job`. Should be used for cleanup.
    ///
    /// - Parameters:
    ///   - key: The key that the `Job` was stored under
    ///   - jobString: A string representation of the `Job`
    /// - Returns: A future `Void` value used to signify completion
    func completed(key: String, jobString: String) -> EventLoopFuture<Void>
}
