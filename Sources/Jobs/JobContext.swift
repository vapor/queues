public struct JobContext {
    public let queueName: JobsQueueName
    public let configuration: JobsConfiguration
    public let logger: Logger
    public let eventLoop: EventLoop
    
    public init(
        queueName: JobsQueueName,
        configuration: JobsConfiguration,
        logger: Logger,
        on eventLoop: EventLoop
    ) {
        self.queueName = queueName
        self.configuration = configuration
        self.logger = logger
        self.eventLoop = eventLoop
    }
}
