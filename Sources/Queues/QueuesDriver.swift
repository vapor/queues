/// A new driver for Queues
public protocol QueuesDriver {
    /// Makes the queue worker
    /// - Parameter context: The context of the job
    func makeQueue(with context: QueueContext) -> any Queue
    
    /// Shuts down the driver
    func shutdown()
    
    /// Shut down the driver asynchronously. Helps avoid calling `.wait()`
    func asyncShutdown() async
}

extension QueuesDriver {
    public func asyncShutdown() async {
        self.shutdown()
    }
}
