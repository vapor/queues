import Vapor

/// The context for a queue.
public struct QueueContext {
    /// The name of the queue
    public let queueName: QueueName

    /// The configuration object
    public let configuration: QueuesConfiguration

    /// The application object
    public let application: Application

    /// The logger object
    public var logger: Logger

    /// An event loop to run the process on
    public let eventLoop: EventLoop

    /// Creates a new JobContext
    /// - Parameters:
    ///   - queueName: The name of the queue
    ///   - configuration: The configuration object
    ///   - application: The application object
    ///   - logger: The logger object
    ///   - eventLoop: An event loop to run the process on
    public init(
        queueName: QueueName,
        configuration: QueuesConfiguration,
        application: Application,
        logger: Logger,
        on eventLoop: EventLoop
    ) {
        self.queueName = queueName
        self.configuration = configuration
        self.application = application
        self.logger = logger
        self.eventLoop = eventLoop
    }

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
