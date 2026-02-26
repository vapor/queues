import NIOCore
import Foundation
import Logging
import Vapor

/// A task that can be queued for future execution.
public protocol Job: AnyJob {
    /// The data associated with a job
    associatedtype Payload: Sendable
    
    /// Called when it's this Job's turn to be dequeued.
    ///
    /// - Parameters:
    ///   - context: The ``QueueContext``.
    ///   - payload: The typed job payload.
    func dequeue(
        _ context: QueueContext,
        _ payload: Payload
    ) -> EventLoopFuture<Void>
    
    /// Called when there is an error at any stage of the Job's execution.
    ///
    /// - Parameters:
    ///   - context: The ``QueueContext``.
    ///   - error: The error returned by the job.
    ///   - payload: The typed job payload.
    func error(
        _ context: QueueContext,
        _ error: any Error,
        _ payload: Payload
    ) -> EventLoopFuture<Void>

    /// Called when there was an error and the job will be retried.
    ///
    /// - Parameter attempt: Number of job attempts which have failed so far.
    /// - Returns: Number of seconds to delay the next retry. Return `0` to place the job back on the queue with no
    ///   delay added. If this method is not implemented, the default is `0`. Returning `-1` is the same as `0`.
    func nextRetryIn(attempt: Int) -> Int
    
    /// Serialize a typed payload to an array of bytes. When `Payload` is `Codable`, this method will default to
    /// encoding to JSON.
    ///
    /// - Parameter payload: The payload to serialize.
    /// - Returns: The array of serialized bytes.
    static func serializePayload(_ payload: Payload) throws -> [UInt8]
    
    /// Deserialize an array of bytes into a typed payload. When `Payload` is `Codable`, this method will default to
    /// decoding from JSON.
    ///
    /// - Parameter bytes: The serialized bytes to decode.
    /// - Returns: A decoded payload.
    static func parsePayload(_ bytes: [UInt8]) throws -> Payload
}

extension Job where Payload: Codable {    
    /// Default implementation for ``Job/serializePayload(_:)-4uro2``.
    public static func serializePayload(_ payload: Payload) throws -> [UInt8] {
        try .init(JSONEncoder().encode(payload))
    }
    
    /// Default implementation for ``Job/parsePayload(_:)-9tn3a``.
    public static func parsePayload(_ bytes: [UInt8]) throws -> Payload {
        try JSONDecoder().decode(Payload.self, from: .init(bytes))
    }
}

extension Job {
    /// Default implementation for ``AnyJob/name``.
    public static var name: String {
        String(describing: Self.self)
    }
    
    /// Default implementation for ``Job/error(_:_:_:)-jzgw``.
    public func error(
        _ context: QueueContext,
        _ error: any Error,
        _ payload: Payload
    ) -> EventLoopFuture<Void> {
        context.eventLoop.makeSucceededVoidFuture()
    }

    /// Default implementation for ``Job/nextRetryIn(attempt:)-5gc93``.
    public func nextRetryIn(attempt: Int) -> Int {
        0
    }
}

/// A type-erased version of ``Job``.
public protocol AnyJob: Sendable {
    /// The name of the job.
    static var name: String { get }

    /// Perform ``Job/dequeue(_:_:)`` after deserializing the raw payload bytes.
    func _dequeue(_ context: QueueContext, id: String, payload: [UInt8]) -> EventLoopFuture<Void>
    
    /// Perform ``Job/error(_:_:_:)-2brrj`` after deserializing the raw payload bytes.
    func _error(_ context: QueueContext, id: String, _ error: any Error, payload: [UInt8]) -> EventLoopFuture<Void>
    
    /// Type-erased accessor for ``Job/nextRetryIn(attempt:)-5gc93``.
    func _nextRetryIn(attempt: Int) -> Int
}

// N.B. These should really not be public.
extension Job {
    // See `AnyJob._nextRetryIn(attempt:)`.
    public func _nextRetryIn(attempt: Int) -> Int {
        self.nextRetryIn(attempt: attempt)
    }

    // See `AnyJob._error(_:id:_:payload:)`.
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
    
    // See `AnyJob._dequeue(_:id:payload:)`.
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

