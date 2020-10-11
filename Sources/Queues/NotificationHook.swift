import NIO

/// Represents an object that can receive notifications about job statuses
public protocol NotificationHook {

    /// Called when the job succeeds
    /// - Parameters:
    ///   - job: The `JobData` associated with the job
    ///   - eventLoop: The eventLoop
    func success(job: JobData, eventLoop: EventLoop) -> EventLoopFuture<Void>

    /// Called when the job returns an error
    /// - Parameters:
    ///   - job: The `JobData` associated with the job
    ///   - error: The error that caused the job to fail
    ///   - eventLoop: The eventLoop
    func error(job: JobData, error: Error, eventLoop: EventLoop) -> EventLoopFuture<Void>
}

extension NotificationHook {
    public func success(job: JobData, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }

    public func error(job: JobData, error: Error, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        eventLoop.future()
    }
}
