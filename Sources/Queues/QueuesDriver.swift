/// A new driver for Queues
public protocol QueuesDriver {
    /// Makes the queue worker
    /// - Parameter context: The context of the job
    func makeQueue(with context: QueueContext) -> Queue

    /// Shuts down the driver
    func shutdown()
}
