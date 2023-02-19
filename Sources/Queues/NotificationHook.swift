import NIOCore
import Foundation

/// Represents an object that can receive notifications about job statuses
public protocol JobEventDelegate {

    /// Called when the job is first dispatched
    /// - Parameters:
    ///   - job: The `JobData` associated with the job
    ///   - eventLoop: The eventLoop
    func dispatched(job: JobEventData, eventLoop: EventLoop) -> EventLoopFuture<Void>

    /// Called when the job is dequeued
    /// - Parameters:
    ///   - jobId: The id of the Job
    ///   - eventLoop: The eventLoop
    func didDequeue(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void>


    /// Called when the job succeeds
    /// - Parameters:
    ///   - jobId: The id of the Job
    ///   - eventLoop: The eventLoop
    func success(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void>

    /// Called when the job returns an error
    /// - Parameters:
    ///   - jobId: The id of the Job
    ///   - error: The error that caused the job to fail
    ///   - eventLoop: The eventLoop
    func error(jobId: String, error: Error, eventLoop: EventLoop) -> EventLoopFuture<Void>
}

extension JobEventDelegate {
    public func dispatched(job: JobEventData, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    public func didDequeue(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    public func success(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    public func error(jobId: String, error: Error, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }
}

/// Data on a job sent via a notification
public struct JobEventData {
    /// The id of the job, assigned at dispatch
    public var id: String

    /// The name of the queue (i.e. `default`)
    public var queueName: String

    /// The job data to be encoded.
    public var payload: [UInt8]

    /// The maxRetryCount for the `Job`.
    public var maxRetryCount: Int

    /// A date to execute this job after
    public var delayUntil: Date?

    /// The date this job was queued
    public var queuedAt: Date

    /// The name of the `Job`
    public var jobName: String

    /// Creates a new `JobStorage` holding object
    public init(id: String, queueName: String, jobData: JobData) {
        self.id = id
        self.queueName = queueName
        self.payload = jobData.payload
        self.maxRetryCount = jobData.maxRetryCount
        self.jobName = jobData.jobName
        self.delayUntil = jobData.delayUntil
        self.queuedAt = jobData.queuedAt
    }
}
