import NIO
import Foundation
import Vapor

/// A task that can be queued for future execution.
public protocol Job: AnyJob {
    
    /// The data associated with a job
    associatedtype Data: JobData
    
    /// Called when it's this Job's turn to be dequeued.
    ///
    /// - Parameters:
    ///   - context: The JobContext. Can be used to store and retrieve services
    ///   - data: The `JobData` for this handler
    /// - Returns: A future `Void` value used to signify completion
    func dequeue(_ context: JobContext, _ data: Data) -> EventLoopFuture<Void>

    
    /// Called when there is an error at any stage of the Job's execution.
    ///
    /// - Parameters:
    ///   - context: The JobContext. Can be used to store and retrieve services
    ///   - error: The error returned by the job.
    /// - Returns: A future `Void` value used to signify completion
    func error(_ context: JobContext, _ error: Error) -> EventLoopFuture<Void>
}

extension Job {
    
    /// The key of the Job
    static var key: String {
        return Data.jobName
    }
    
    /// See `Job.error`
    func error(_ context: JobContext, _ error: Error) -> EventLoopFuture<Void> {
        return context.eventLoop.future()
    }
    
    /// See `AnyJob.anyDequeue`
    public func anyDequeue(_ context: JobContext, _ storage: JobStorage) -> EventLoopFuture<Void> {
        do {
            let data = try JSONDecoder().decode(Data.self, from: storage.data)
            return self.dequeue(context, data)
        } catch {
            return context.eventLoop.future(error: error)
        }
    }
}
