import Foundation
import NIO

/// A type-erased version of `Job`
public protocol AnyJob {
    
    /// The name of the `Job`
    static var jobName: String { get }
    
    /// Dequeues the `Job`
    ///
    /// - Parameters:
    ///   - context: The context for the job
    ///   - storage: The `JobStorage` metadata object
    /// - Returns: A future void, signifying completion
    func anyDequeue(_ context: JobContext, _ storage: JobStorage) -> EventLoopFuture<Void>
    
    /// Handles errors thrown from `anyDequeue`
    ///
    /// - Parameters:
    ///   - context: The context for the job
    ///   - error: The error thrown
    ///   - storage: The JobStorage
    /// - Returns: A future void, signifying completion
    func error(_ context: JobContext, _ error: Error, _ storage: JobStorage) -> EventLoopFuture<Void>
}
