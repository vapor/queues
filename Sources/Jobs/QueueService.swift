import Foundation
import Vapor

public struct QueueService: Service {
    let refreshInterval: TimeAmount
    let persistenceLayer: JobsPersistenceLayer
    let persistenceKey: String
    let container: Container
    
    public func dispatch(job: Job) -> EventLoopFuture<Void> {
        return container.future()
    }
}
