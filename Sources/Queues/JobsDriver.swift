/// A new driver for Jobs
public protocol JobsDriver {
    
    /// Makes the queue worker
    /// - Parameter context: The context of the job
    func makeQueue(with context: JobContext) -> JobsQueue
    
    /// Shuts down the driver
    func shutdown()
}
