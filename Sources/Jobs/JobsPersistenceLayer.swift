import Foundation
import NIO
import Vapor

/// A type that can store and retrieve jobs from a persistence layer
public protocol JobsPersistenceLayer: Service {
    
    /// The event loop to be run on
    var eventLoop: EventLoop { get }
    
    /// Returns a `JobData` wrapper for a specified key.
    ///
    /// - Parameters:
    ///   - key: The key that the data is stored under.
    /// - Returns: The retrieved `JobStorage`, if it exists.
    func get(key: String) -> EventLoopFuture<JobStorage?>
    
    /// Handles adding a `Job` to the persistence layer for future processing.
    ///
    /// - Parameters:
    ///   - key: The key to add the `Job` under.
    ///   - jobStorage: The `JobStorage` object to persist.
    /// - Returns: A future `Void` value used to signify completion
    func set(key: String, jobStorage: JobStorage) -> EventLoopFuture<Void>
    
    /// Called upon completion of the `Job`. Should be used for cleanup.
    ///
    /// - Parameters:
    ///   - key: The key that the `Job` was stored under
    ///   - jobStorage: The jobStorage holding the `Job` that was completed
    /// - Returns: A future `Void` value used to signify completion
    func completed(key: String, jobStorage: JobStorage) -> EventLoopFuture<Void>
    
    /// Returns the processing version of the key
    ///
    /// - Parameter key: The base key
    /// - Returns: The processing key
    func processingKey(key: String) -> String


    /// Requeues a job due to a delay
    /// - Parameter key: The key of the job
    /// - Parameter jobStorage: The jobStorage holding the `Job` to be requeued
    func requeue(key: String, jobStorage: JobStorage) -> EventLoopFuture<Void>
}
