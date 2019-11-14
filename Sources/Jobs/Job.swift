import NIO
import Foundation
import Vapor

/// A task that can be queued for future execution.
public protocol Job: AnyJob {
    /// The data associated with a job
    associatedtype Data: Codable
    
    /// Called when it's this Job's turn to be dequeued.
    ///
    /// - Parameters:
    ///   - context: The JobContext. Can be used to store and retrieve services
    ///   - data: The data for this handler
    /// - Returns: A future `Void` value used to signify completion
    func dequeue(_ context: JobContext, _ data: Data) -> EventLoopFuture<Void>

    
    /// Called when there is an error at any stage of the Job's execution.
    ///
    /// - Parameters:
    ///   - context: The JobContext. Can be used to store and retrieve services
    ///   - error: The error returned by the job.
    /// - Returns: A future `Void` value used to signify completion
    func error(_ context: JobContext, _ error: Error, _ data: Data) -> EventLoopFuture<Void>
}

public extension Job {
    /// The jobName of the Job
    static var jobName: String {
        return String(describing: Self.self)
    }
    
    /// See `Job.error`
    func error(_ context: JobContext, _ error: Error, _ data: Data) -> EventLoopFuture<Void> {
        return context.eventLoop.future()
    }
    
    func error(_ context: JobContext, _ error: Error, _ storage: JobStorage) -> EventLoopFuture<Void> {
        do {
            let data = try JSONDecoder().decode(Data.self, from: storage.data)
            return self.error(context, error, data)
        } catch {
            return context.eventLoop.future(error: error)
        }
    }
    
    /// See `AnyJob.anyDequeue`
    func anyDequeue(_ context: JobContext, _ storage: JobStorage) -> EventLoopFuture<Void> {
        do {
            let data = try JSONDecoder().decode(Data.self, from: storage.data)
            return self.dequeue(context, data)
        } catch {
            return context.eventLoop.future(error: error)
        }
    }
}

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
