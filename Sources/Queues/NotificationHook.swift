import NIO

/// Represents an object that can receive notifications about job statuses
public protocol NotificationHook {

    /// Called when the job is first dispatched
    /// - Parameters:
    ///   - job: The `JobData` associated with the job
    ///   - eventLoop: The eventLoop
    func dispatched(job: NotificationJobData, eventLoop: EventLoop) -> EventLoopFuture<Void>


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

extension NotificationHook {
    public func dispatched(job: NotificationJobData, eventLoop: EventLoop) -> EventLoopFuture<Void> {
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
public struct NotificationJobData {
    /// The id of the job, assigned at dispatch
    public let id: String

    /// The job data to be encoded.
    public let payload: [UInt8]

    /// The maxRetryCount for the `Job`.
    public let maxRetryCount: Int

    /// A date to execute this job after
    public let delayUntil: Date?

    /// The date this job was queued
    public let queuedAt: Date

    /// The name of the `Job`
    public let jobName: String

    /// Creates a new `JobStorage` holding object
    public init(id: String, jobData: JobData) {
        self.id = id
        self.payload = jobData.payload
        self.maxRetryCount = jobData.maxRetryCount
        self.jobName = jobData.jobName
        self.delayUntil = jobData.delayUntil
        self.queuedAt = jobData.queuedAt
    }
}
