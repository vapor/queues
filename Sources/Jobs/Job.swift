import NIO
import Foundation
import Vapor

/// A task that can be queued for future execution.
public protocol Job: AnyJob {
    /// The data associated with a job
    associatedtype Payload
    
    /// Called when it's this Job's turn to be dequeued.
    ///
    /// - Parameters:
    ///   - context: The JobContext. Can be used to store and retrieve services
    ///   - data: The data for this handler
    /// - Returns: A future `Void` value used to signify completion
    func dequeue(
        _ context: JobContext,
        _ payload: Payload
    ) -> EventLoopFuture<Void>

    
    /// Called when there is an error at any stage of the Job's execution.
    ///
    /// - Parameters:
    ///   - context: The JobContext. Can be used to store and retrieve services
    ///   - error: The error returned by the job.
    /// - Returns: A future `Void` value used to signify completion
    func error(
        _ context: JobContext,
        _ error: Error,
        _ payload: Payload
    ) -> EventLoopFuture<Void>
    
    static func serializePayload(_ payload: Payload) throws -> [UInt8]
    static func parsePayload(_ bytes: [UInt8]) throws -> Payload
}

extension Job where Payload: Codable {
    public static func serializePayload(_ payload: Payload) throws -> [UInt8] {
        try .init(JSONEncoder().encode(payload))
    }
    
    public static func parsePayload(_ bytes: [UInt8]) throws -> Payload {
        try JSONDecoder().decode(Payload.self, from: .init(bytes))
    }
}

extension Job {
    /// The jobName of the Job
    public static var name: String {
        return String(describing: Self.self)
    }
    
    public func error(
        _ context: JobContext,
        _ error: Error,
        _ payload: Payload
    ) -> EventLoopFuture<Void> {
        context.eventLoop.makeSucceededFuture(())
    }
    
    public func _error(_ context: JobContext, _ error: Error, payload: [UInt8]) -> EventLoopFuture<Void> {
        do {
            return try self.error(context, error, Self.parsePayload(payload))
        } catch {
            return context.eventLoop.makeFailedFuture(error)
        }
    }
    
    public func _dequeue(_ context: JobContext, payload: [UInt8]) -> EventLoopFuture<Void> {
        do {
            return try self.dequeue(context, Self.parsePayload(payload))
        } catch {
            return context.eventLoop.makeFailedFuture(error)
        }
    }
}

/// A type-erased version of `Job`
public protocol AnyJob {
    /// The name of the `Job`
    static var name: String { get }

    /// Dequeues the `Job`
    ///
    /// - Parameters:
    ///   - context: The context for the job
    ///   - storage: The `JobStorage` metadata object
    /// - Returns: A future void, signifying completion
    func _dequeue(_ context: JobContext, payload: [UInt8]) -> EventLoopFuture<Void>

    /// Handles errors thrown from `anyDequeue`
    ///
    /// - Parameters:
    ///   - context: The context for the job
    ///   - error: The error thrown
    ///   - storage: The JobStorage
    /// - Returns: A future void, signifying completion
    func _error(_ context: JobContext, _ error: Error, payload: [UInt8]) -> EventLoopFuture<Void>
}
