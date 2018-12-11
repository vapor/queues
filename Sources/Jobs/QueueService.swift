import Foundation
import Vapor

/// A `Service` used to dispatch `Jobs`
public struct QueueService: Service {
    
    /// See `JobsProvider`.`refreshInterval`
    let refreshInterval: TimeAmount
    
    /// See `JobsProvider`.`persistenceLayer`
    let persistenceLayer: JobsPersistenceLayer
    
    /// See `JobsProvider`.`persistenceKey`
    let persistenceKey: String
    
    /// An `EventLoopGroup` that can be used to generate future values
    let worker: EventLoopGroup
    
    /// Dispatches a job to the queue for future execution
    ///
    /// - Parameters:
    ///   - job: The `Job` to dispatch to the queue
    ///   - maxRetryCount: The number of retries to attempt upon error before calling `Job`.`error()`
    ///   - queue: The queue to run this job on
    /// - Returns: A future `Void` value used to signify completion
    public func dispatch<J: Job>(job: J, maxRetryCount: Int = 0, queue: QueueType = .default) -> EventLoopFuture<Void> {
        return persistenceLayer.set(key: queue.makeKey(with: persistenceKey),
                                    job: job,
                                    maxRetryCount: maxRetryCount)
            .transform(to: ())
    }
}
