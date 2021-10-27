import Vapor
import NIOCore
import Foundation

#if compiler(>=5.5) && canImport(_Concurrency)
/// Describes a job that can be scheduled and repeated
@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
public protocol AsyncScheduledJob: ScheduledJob {
    var name: String { get }
    
    /// The method called when the job is run
    /// - Parameter context: A `JobContext` that can be used
    func run(context: QueueContext) async throws
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension AsyncScheduledJob {
    public var name: String { "\(Self.self)" }
    
    public func run(context: QueueContext) -> EventLoopFuture<Void> {
        let promise = context.eventLoop.makePromise(of: Void.self)
        promise.completeWithTask {
            try await self.run(context: context)
        }
        return promise.futureResult
    }
}
#endif
