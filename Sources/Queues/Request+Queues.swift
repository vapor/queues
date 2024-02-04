import Foundation
import Vapor
import NIOCore

extension Request {
    /// Returns the default job `Queue`
    public var queue: any Queue {
        self.queues(.default)
    }

    /// Returns the specific job `Queue` for the given queue name
    /// - Parameter queue: The queue name
    public func queues(_ queue: QueueName) -> any Queue {
        self.application.queues.queue(
            queue,
            logger: self.logger,
            on: self.eventLoop
        )
    }
}
