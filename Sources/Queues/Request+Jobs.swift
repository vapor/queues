import Foundation
import Vapor
import NIO

extension Request {
    
    /// The `JobsQueue` object
    public var jobs: JobsQueue {
        self.jobs(.default)
    }
    
    /// A jobs queue for a specific queue name
    /// - Parameter queue: The queue name
    public func jobs(_ queue: JobsQueueName) -> JobsQueue {
        self.application.queues.queue(
            queue,
            logger: self.logger,
            on: self.eventLoop
        )
    }
}
