import Foundation
import Vapor

public struct QueueService: Service {
    let refreshInterval: TimeAmount
    let persistenceLayer: JobsPersistenceLayer
    let persistenceKey: String
    let worker: EventLoopGroup
    
    public func dispatch<J: Job>(job: J, queue: QueueType = .default) -> EventLoopFuture<Void> {
        return persistenceLayer.set(key: queue.makeKey(with: persistenceKey), job: job, worker: worker).transform(to: ())
    }
}
