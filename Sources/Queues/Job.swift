import NIOCore
import Foundation
import Logging
import Vapor

/// A task that can be queued for future execution.
public protocol Job: AnyJob {
    /// The data associated with a job
    associatedtype Payload: Sendable
    
    /// Called when it's this Job's turn to be dequeued.
    /// - Parameters:
    ///   - context: The JobContext. Can be used to store and retrieve services
    ///   - payload: The data for this handler
    func dequeue(
        _ context: QueueContext,
        _ payload: Payload
    ) -> EventLoopFuture<Void>
    
    /// Called when there is an error at any stage of the Job's execution.
    /// - Parameters:
    ///   - context: The JobContext. Can be used to store and retrieve services
    ///   - error: The error returned by the job.
    ///   - payload: The typed payload for the job
    func error(
        _ context: QueueContext,
        _ error: any Error,
        _ payload: Payload
    ) -> EventLoopFuture<Void>

    /// Called when there was an error and job will be retired.
    ///
    /// - Parameters:
    ///     - attempt: Number of job attempts which failed
    /// - Returns: Number of seconds for which next retry will be delayed.
    ///   Return `-1` if you want to retry job immediately without putting it back to the queue.
    func nextRetryIn(attempt: Int) -> Int
    
    static func serializePayload(_ payload: Payload) throws -> [UInt8]
    static func parsePayload(_ bytes: [UInt8]) throws -> Payload
}

extension Job where Payload: Codable {
    
    /// Serialize a payload into Data
    /// - Parameter payload: The payload
    public static func serializePayload(_ payload: Payload) throws -> [UInt8] {
        try .init(JSONEncoder().encode(payload))
    }
    
    /// Parse bytes into the payload
    /// - Parameter bytes: The Payload
    public static func parsePayload(_ bytes: [UInt8]) throws -> Payload {
        try JSONDecoder().decode(Payload.self, from: .init(bytes))
    }
}

extension Job {
    /// The jobName of the Job
    public static var name: String {
        return String(describing: Self.self)
    }
    
    /// See `Job`.`error`
    public func error(
        _ context: QueueContext,
        _ error: any Error,
        _ payload: Payload
    ) -> EventLoopFuture<Void> {
        context.eventLoop.makeSucceededVoidFuture()
    }

    /// See `Job`.`nextRetryIn`
    public func nextRetryIn(attempt: Int) -> Int {
        return -1
    }

    public func _nextRetryIn(attempt: Int) -> Int {
        return nextRetryIn(attempt: attempt)
    }

    public func _error(_ context: QueueContext, id: String, _ error: any Error, payload: [UInt8]) -> EventLoopFuture<Void> {
        var context = context
        context.logger[metadataKey: "queue"] = "\(context.queueName.string)"
        context.logger[metadataKey: "job_id"] = "\(id)"
        do {
            return try self.error(context, error, Self.parsePayload(payload))
        } catch {
            return context.eventLoop.makeFailedFuture(error)
        }
    }
    
    public func _dequeue(_ context: QueueContext, id: String, payload: [UInt8]) -> EventLoopFuture<Void> {
        var context = context
        context.logger[metadataKey: "queue"] = "\(context.queueName.string)"
        context.logger[metadataKey: "job_id"] = "\(id)"
        do {
            return try self.dequeue(context, Self.parsePayload(payload))
        } catch {
            return context.eventLoop.makeFailedFuture(error)
        }
    }
}

/// A type-erased version of `Job`
public protocol AnyJob: Sendable {
    /// The name of the `Job`
    static var name: String { get }
    func _dequeue(_ context: QueueContext, id: String, payload: [UInt8]) -> EventLoopFuture<Void>
    func _error(_ context: QueueContext, id: String, _ error: any Error, payload: [UInt8]) -> EventLoopFuture<Void>
    func _nextRetryIn(attempt: Int) -> Int
}
