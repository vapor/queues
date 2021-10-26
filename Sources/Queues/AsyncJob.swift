import Vapor
import NIOCore
import Foundation

#if compiler(>=5.5) && canImport(_Concurrency)
/// A task that can be queued for future execution.
@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public protocol AsyncJob: AnyAsyncJob, AnyJob {
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
        _ error: Error,
        _ payload: Payload
    ) async throws

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

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension AsyncJob where Payload: Codable {
    
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

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension AsyncJob {
    /// The jobName of the Job
    public static var name: String {
        return String(describing: Self.self)
    }
    
    /// See `Job`.`error`
    public func error(
        _ context: QueueContext,
        _ error: Error,
        _ payload: Payload
    ) async throws {
        return
    }

    /// See `Job`.`nextRetryIn`
    public func nextRetryIn(attempt: Int) -> Int {
        return -1
    }

    public func _nextRetryIn(attempt: Int) -> Int {
        return nextRetryIn(attempt: attempt)
    }

    public func _error(_ context: QueueContext, id: String, _ error: Error, payload: [UInt8]) async throws {
        var contextCopy = context
        contextCopy.logger[metadataKey: "job_id"] = .string(id)
        return try await self.error(contextCopy, error, Self.parsePayload(payload))
    }
    
    public func _dequeue(_ context: QueueContext, id: String, payload: [UInt8]) async throws {
        var contextCopy = context
        contextCopy.logger[metadataKey: "job_id"] = .string(id)
        return try await self.dequeue(contextCopy, Self.parsePayload(payload))
    }
    
    /// See `Job`.`error`
    public func error(
        _ context: QueueContext,
        _ error: Error,
        _ payload: Payload
    ) -> EventLoopFuture<Void> {
        let promise = context.eventLoop.makePromise(of: Void.self)
        promise.completeWithTask {
            try await self.error(context, error, payload)
        }
        return promise.futureResult
    }

    public func _error(_ context: QueueContext, id: String, _ error: Error, payload: [UInt8]) -> EventLoopFuture<Void> {
        let promise = context.eventLoop.makePromise(of: Void.self)
        promise.completeWithTask {
            try await self._error(context, id: id, error, payload: payload)
        }
        return promise.futureResult
    }
    
    public func _dequeue(_ context: QueueContext, id: String, payload: [UInt8]) -> EventLoopFuture<Void> {
        let promise = context.eventLoop.makePromise(of: Void.self)
        promise.completeWithTask {
            try await self._dequeue(context, id: id, payload: payload)
        }
        return promise.futureResult
    }
}

/// A type-erased version of `Job`
@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public protocol AnyAsyncJob {
    /// The name of the `Job`
    static var name: String { get }
    func _dequeue(_ context: QueueContext, id: String, payload: [UInt8]) async throws
    func _error(_ context: QueueContext, id: String, _ error: Error, payload: [UInt8]) async throws
    func _nextRetryIn(attempt: Int) -> Int
}
#endif