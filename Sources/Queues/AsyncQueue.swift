import Foundation
import Vapor
import NIOCore

public protocol AsyncQueue: Queue {
    /// The job context
    var context: QueueContext { get }
    
    /// Gets the next job to be run
    /// - Parameter id: The ID of the job
    func get(_ id: JobIdentifier) async throws -> JobData
    
    /// Sets a job that should be run in the future
    /// - Parameters:
    ///   - id: The ID of the job
    ///   - data: Data for the job
    func set(_ id: JobIdentifier, to data: JobData) async throws
    
    /// Removes a job from the queue
    /// - Parameter id: The ID of the job
    func clear(_ id: JobIdentifier) async throws

    /// Pops the next job in the queue
    func pop() async throws -> JobIdentifier?
    
    /// Pushes the next job into a queue
    /// - Parameter id: The ID of the job
    func push(_ id: JobIdentifier) async throws
}

extension AsyncQueue {
    public func get(_ id: JobIdentifier) -> EventLoopFuture<JobData> {
        self.context.eventLoop.makeFutureWithTask { try await self.get(id) }
    }
    
    public func set(_ id: JobIdentifier, to data: JobData) -> EventLoopFuture<Void> {
        self.context.eventLoop.makeFutureWithTask { try await self.set(id, to: data) }
    }
    
    public func clear(_ id: JobIdentifier) -> EventLoopFuture<Void> {
        self.context.eventLoop.makeFutureWithTask { try await self.clear(id) }
    }
    
    public func pop() -> EventLoopFuture<JobIdentifier?> {
        self.context.eventLoop.makeFutureWithTask { try await self.pop() }
    }
    
    public func push(_ id: JobIdentifier) -> EventLoopFuture<Void> {
        self.context.eventLoop.makeFutureWithTask { try await self.push(id) }
    }
}

extension Queue {
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
    ) async throws {
        var logger = self.logger
        logger[metadataKey: "queue"] = "\(self.queueName.string)"
        logger[metadataKey: "job-id"] = "\(id.string)"
        logger[metadataKey: "job-name"] = "\(J.name)"
        
        let storage = JobData(
            payload: try J.serializePayload(payload),
            maxRetryCount: maxRetryCount,
            jobName: J.name,
            delayUntil: delayUntil,
            queuedAt: .init()
        )

        logger.trace("Storing job data")
        try await self.set(id, to: storage).get()
        logger.trace("Pusing job to queue")
        try await self.push(id).get()
        logger.info("Dispatched job")
        
        await self.sendNotification(of: "dispatch", logger: logger) {
            try await $0.dispatched(job: .init(id: id.string, queueName: self.queueName.string, jobData: storage), eventLoop: self.eventLoop).get()
        }
    }
}
