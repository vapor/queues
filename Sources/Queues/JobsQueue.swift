/// A type that can store and retrieve jobs from a persistence layer
public protocol JobsQueue {
    
    /// The job context
    var context: JobContext { get }
    
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

extension JobsQueue {
    
    /// The EventLoop for a job queue
    public var eventLoop: EventLoop {
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
    public var queueName: JobsQueueName {
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
