import Foundation
import Vapor

public struct QueueService: Service {
    let refreshInterval: TimeAmount
    let persistenceLayer: JobsPersistenceLayer
    let persistenceKey: String
    let worker: EventLoopGroup
    
    public func dispatch<J: Job>(job: J, maxRetryCount: Int = 0, queue: QueueType = .default) -> EventLoopFuture<Void> {
        return persistenceLayer.set(key: queue.makeKey(with: persistenceKey),
                                    job: job,
                                    maxRetryCount: maxRetryCount,
                                    worker: worker)
            .transform(to: ())
    }
}
