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
    ///   - worker: An `EventLoopGroup` that can be used to generate future values
    /// - Returns: A future `Void` value used to signify completion
    func dequeue(context: JobContext, data: Foundation.Data) -> EventLoopFuture<Void>

    
    /// Called when there is an error at any stage of the Job's execution.
    ///
    /// - Parameters:
    ///   - context: The JobContext. Can be used to store and retrieve services
    ///   - error: The error returned by the job.
    ///   - worker: An `EventLoopGroup` that can be used to generate future values
    /// - Returns: A future `Void` value used to signify completion
    func error(context: JobContext, error: Error) -> EventLoopFuture<Void>
}

extension Job {
    static var key: String {
        return Data.jobName
    }
    
    func error(context: JobContext, error: Error) -> EventLoopFuture<Void> {
        return context.eventLoop.future()
    }
    
    public func anyDequeue(context: JobContext, storage: JobStorage) -> EventLoopFuture<Void> {
        guard let data = try? JSONDecoder().decode(Foundation.Data.self, from: storage.data) else {
            return context.eventLoop.future(error: Abort(.internalServerError, reason: "Could not convert data"))
        }
        
        return self.dequeue(context: context, data: data)
    }
}
