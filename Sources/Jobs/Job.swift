import NIO
import Foundation


/// A task that can be queued for future execution.
public protocol Job: Codable {
    
    /// Called when it's this Job's turn to be dequeued.
    ///
    /// - Parameters:
    ///   - context: The JobContext. Can be used to store and retrieve services
    ///   - worker: An `EventLoopGroup` that can be used to generate future values
    /// - Returns: A future `Void` value used to signify completion
    func dequeue(context: JobContext, worker: EventLoopGroup) -> EventLoopFuture<Void>
    
    
    /// Called when there is an error at any stage of the Job's execution.
    ///
    /// - Parameters:
    ///   - context: The JobContext. Can be used to store and retrieve services
    ///   - error: The error returned by the job.
    ///   - worker: An `EventLoopGroup` that can be used to generate future values
    /// - Returns: A future `Void` value used to signify completion
    func error(context: JobContext, error: Error, worker: EventLoopGroup) -> EventLoopFuture<Void>
}

extension Job {
    public func error(context: JobContext, error: Error, worker: EventLoopGroup) -> EventLoopFuture<Void> {
        return worker.future()
    }
    
    /// Generates a string value from a `Job` using `JobData` and `JSONEncoder`
    ///
    /// - Parameters:
    ///   - key: The persistence key specified by the end-user
    ///   - maxRetryCount: The maxRetryCount for the job
    ///   - id: A unique ID for the job
    /// - Returns: A string representing the job. Will be `nil` if there is an encoding error.
    public func stringValue(key: String, maxRetryCount: Int, id: String) -> String? {
        let jobData = JobData(key: key, data: self, maxRetryCount: maxRetryCount, id: id)
        guard let data = try? JSONEncoder().encode(jobData) else { return nil }
        guard let jobString = String(data: data, encoding: .utf8) else { return nil }
        return jobString
    }
}
