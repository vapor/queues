#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore

/// Represents an object that can receive notifications about job statuses
@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public protocol AsyncJobEventDelegate: JobEventDelegate {
    /// Called when the job is first dispatched
    /// - Parameters:
    ///   - job: The `JobData` associated with the job
    func dispatched(job: JobEventData) async throws

    /// Called when the job is dequeued
    /// - Parameters:
    ///   - jobId: The id of the Job
    func didDequeue(jobId: String) async throws

    /// Called when the job succeeds
    /// - Parameters:
    ///   - jobId: The id of the Job
    func success(jobId: String) async throws

    /// Called when the job returns an error
    /// - Parameters:
    ///   - jobId: The id of the Job
    ///   - error: The error that caused the job to fail
    func error(jobId: String, error: Error) async throws
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension AsyncJobEventDelegate {
    public func dispatched(job: JobEventData) async throws { }
    public func didDequeue(jobId: String) async throws { }
    public func success(jobId: String) async throws { }
    public func error(jobId: String, error: Error) async throws { }
    
    public func dispatched(job: JobEventData, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.makeFutureWithTask {
            try await self.dispatched(job: job)
        }
    }
    
    public func didDequeue(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.makeFutureWithTask {
            try await self.didDequeue(jobId: jobId)
        }
    }
    
    public func success(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.makeFutureWithTask {
            try await self.success(jobId: jobId)
        }
    }
    
    public func error(jobId: String, error: Error, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.makeFutureWithTask {
            try await self.error(jobId: jobId, error: error)
        }
    }
}
#endif
