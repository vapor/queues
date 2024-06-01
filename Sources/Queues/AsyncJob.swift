import Vapor
import NIOCore
import Foundation

/// A task that can be queued for future execution.
public protocol AsyncJob: Job {
    /// The data associated with a job
    associatedtype Payload
    
    /// Called when it's this Job's turn to be dequeued.
    /// - Parameters:
    ///   - context: The JobContext. Can be used to store and retrieve services
    ///   - payload: The data for this handler
    func dequeue(
        _ context: QueueContext,
        _ payload: Payload
    ) async throws
    
    /// Called when there is an error at any stage of the Job's execution.
    /// - Parameters:
    ///   - context: The JobContext. Can be used to store and retrieve services
    ///   - error: The error returned by the job.
    ///   - payload: The typed payload for the job
    func error(
        _ context: QueueContext,
        _ error: any Error,
        _ payload: Payload
    ) async throws
}

extension AsyncJob {

    public func dequeue(_ context: QueueContext, _ payload: Payload) -> EventLoopFuture<Void> {
        let promise = context.eventLoop.makePromise(of: Void.self)
        promise.completeWithTask {
            try await self.dequeue(context, payload)
        }
        return promise.futureResult
    }
    
    public func error(_ context: QueueContext, _ error: any Error, _ payload: Payload) -> EventLoopFuture<Void> {
        let promise = context.eventLoop.makePromise(of: Void.self)
        promise.completeWithTask {
            try await self.error(context, error, payload)
        }
        return promise.futureResult
    }
    
    public func error(_ context: QueueContext, _ error: any Error, _ payload: Payload) async throws {
        return
    }
}
