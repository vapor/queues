/// A type that can store and retrieve jobs from a persistence layer
public protocol JobsQueue {
    var context: JobContext { get }
    
    func get(_ id: JobIdentifier) -> EventLoopFuture<JobData>
    func set(_ id: JobIdentifier, to storage: JobData) -> EventLoopFuture<Void>
    func clear(_ id: JobIdentifier) -> EventLoopFuture<Void>

    func pop() -> EventLoopFuture<JobIdentifier?>
    func push(_ id: JobIdentifier) -> EventLoopFuture<Void>
}

extension JobsQueue {
    public var eventLoop: EventLoop {
        self.context.eventLoop
    }
    
    public var logger: Logger {
        self.context.logger
    }
    
    public var configuration: JobsConfiguration {
        self.context.configuration
    }
    
    public var queueName: JobsQueueName {
        self.context.queueName
    }
    
    public var key: String {
        self.queueName.makeKey(with: self.configuration.persistenceKey)
    }
    
    public func dispatch<J>(
        _ job: J.Type,
        _ payload: J.Payload,
        maxRetryCount: Int = 0,
        delayUntil: Date? = nil
    ) -> EventLoopFuture<Void>
        where J: Job
    {
        let bytes: [UInt8]
        do {
            bytes = try J.serializePayload(payload)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
        let id = JobIdentifier()
        let storage = JobData(
            payload: bytes,
            maxRetryCount: maxRetryCount,
            jobName: J.name,
            delayUntil: delayUntil,
            queuedAt: Date()
        )
        return self.set(id, to: storage).flatMap {
            self.push(id)
        }.map { _ in
            self.logger.info("Dispatched queue job", metadata: [
                "job_id": .string("\(id)"),
                "queue": .string(self.queueName.string)
            ])
        }
    }
}
