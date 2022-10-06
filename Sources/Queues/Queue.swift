
import Foundation
import Logging
import Metrics
import NIOCore

/// A type that can store and retrieve jobs from a persistence layer
public protocol Queue: Sendable {
    /// The job context
    var context: QueueContext { get }

    /// Gets the next job to be run
    /// - Parameter id: The ID of the job
    func get(_ id: JobIdentifier) -> EventLoopFuture<JobData>

    /// Sets a job that should be run in the future
    /// - Parameters:
    ///   - id: The ID of the job
    ///   - data: Data for the job
    func set(_ id: JobIdentifier, to data: JobData) -> EventLoopFuture<Void>

    /// Removes a job from the queue
    /// - Parameter id: The ID of the job
    func clear(_ id: JobIdentifier) -> EventLoopFuture<Void>

    /// Pops the next job in the queue
    func pop() -> EventLoopFuture<JobIdentifier?>

    /// Pushes the next job into a queue
    /// - Parameter id: The ID of the job
    func push(_ id: JobIdentifier) -> EventLoopFuture<Void>
}

extension Queue {
    /// The EventLoop for a job queue
    public var eventLoop: any EventLoop {
        self.context.eventLoop
    }

    /// A logger
    public var logger: Logger {
        self.context.logger
    }

    /// The configuration for the queue
    public var configuration: QueuesConfiguration {
        self.context.configuration
    }

    /// The queue's name
    public var queueName: QueueName {
        self.context.queueName
    }

    /// The key name of the queue
    public var key: String {
        self.queueName.makeKey(with: self.configuration.persistenceKey)
    }

    /// Dispatch a job into the queue for processing
    /// - Parameters:
    ///   - job: The Job type
    ///   - payload: The payload data to be dispatched
    ///   - maxRetryCount: Number of times to retry this job on failure
    ///   - delayUntil: Delay the processing of this job until a certain date
    public func dispatch<J: Job>(
        _ job: J.Type,
        _ payload: J.Payload,
        maxRetryCount: Int = 0,
        delayUntil: Date? = nil,
        id: JobIdentifier = .init()
    ) -> EventLoopFuture<Void> {
        var logger_ = self.logger
        logger_[metadataKey: "queue"] = "\(self.queueName.string)"
        logger_[metadataKey: "job-id"] = "\(id.string)"
        logger_[metadataKey: "job-name"] = "\(J.name)"
        let logger = logger_

        let bytes: [UInt8]
        do {
            bytes = try J.serializePayload(payload)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }

        let storage = JobData(
            payload: bytes,
            maxRetryCount: maxRetryCount,
            jobName: J.name,
            delayUntil: delayUntil,
            queuedAt: Date()
        )

        logger.trace("Storing job data")
        return self.set(id, to: storage).flatMap {
            logger.trace("Pusing job to queue")
            return self.push(id)
        }.flatMapWithEventLoop { _, eventLoop in
            Counter(label: "dispatched.jobs.counter", dimensions: [("queueName", self.queueName.string)]).increment()
            self.logger.info("Dispatched queue job", metadata: [
                "job_id": .string(id.string),
                "job_name": .string(job.name),
                "queue": .string(self.queueName.string),
            ])
            return self.sendNotification(of: "dispatch", logger: logger) {
                $0.dispatched(job: .init(id: id.string, queueName: self.queueName.string, jobData: storage), eventLoop: eventLoop)
            }
        }
    }
}

extension Queue {
    func sendNotification(
        of kind: String, logger: Logger,
        _ notification: @escaping @Sendable (_ hook: any JobEventDelegate) -> EventLoopFuture<Void>
    ) -> EventLoopFuture<Void> {
        logger.trace("Sending notification", metadata: ["kind": "\(kind)"])
        return self.configuration.notificationHooks.map {
            notification($0).flatMapErrorWithEventLoop { error, eventLoop in
                logger.warning("Failed to send notification", metadata: ["kind": "\(kind)", "error": "\(error)"])
                return eventLoop.makeSucceededVoidFuture()
            }
        }.flatten(on: self.eventLoop)
    }

    func sendNotification(
        of kind: String, logger: Logger,
        _ notification: @escaping @Sendable (_ hook: any JobEventDelegate) async throws -> Void
    ) async {
        logger.trace("Sending notification", metadata: ["kind": "\(kind)"])
        for hook in self.configuration.notificationHooks {
            do {
                try await notification(hook)
            } catch {
                logger.warning("Failed to send notification", metadata: ["kind": "\(kind)", "error": "\(error)"])
            }
        }
    }
}
