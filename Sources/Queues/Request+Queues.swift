import Foundation
import Vapor
import NIOCore

extension Request {
    /// Get the default ``Queue``.
    public var queue: any Queue {
        self.queues(.default)
    }

    /// Create or look up an instance of a named ``Queue`` and bind it to this request's event loop.
    ///
    /// - Parameter queue: The queue name
    public func queues(_ queue: QueueName, logger: Logger? = nil) -> any Queue {
        self.application.queues.queue(queue, logger: logger ?? self.logger, on: self.eventLoop)
    }
}
