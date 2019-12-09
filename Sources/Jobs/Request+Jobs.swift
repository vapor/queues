import Foundation
import Vapor
import NIO

extension Request {
    public var jobs: JobsQueue {
        self.jobs(.default)
    }

    public func jobs(_ queue: JobsQueueName) -> JobsQueue {
        self.application.jobs.queue(
            queue,
            logger: self.logger,
            on: self.eventLoop
        )
    }
}
