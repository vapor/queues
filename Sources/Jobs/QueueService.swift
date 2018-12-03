import Foundation
import Vapor

public struct QueueService: Service {
    let refreshInterval: TimeAmount
    let persistenceLayer: JobsPersistenceLayer
    let persistenceKey: String
    
    public func dispatch(job: Job) -> EventLoopFuture<Void> {
        return persistenceLayer.set(key: persistenceKey, jobs: [job]).transform(to: ())
    }
}
