import NIO

/// Represents an object that can receive notifications about job statuses
public protocol NotificationHook {

    /// Called when the job succeeds
    /// - Parameter job: The `JobData` associated with the job
    func success(job: JobData) -> EventLoopFuture<Void>

    /// Called when the job returns an error
    /// - Parameters:
    ///   - job: The `JobData` associated with the job
    ///   - error: The error that caused the job to fail
    func error(job: JobData, error: Error) -> EventLoopFuture<Void>
}
