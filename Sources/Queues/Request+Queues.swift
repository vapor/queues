import Foundation
import Vapor
import NIO

extension Request {
    /// Returns the default job `Queue`
    public var queue: Queue {
        self.queues(.default)
    }
    
    /// Returns the specific job `Queue` for the given queue name
    /// - Parameter queue: The queue name
    public func queues(_ queue: QueueName) -> Queue {
        self.application.queues.queue(
            queue,
            logger: self.logger,
            on: self.eventLoop
        )
    }
}
