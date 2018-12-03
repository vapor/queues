import Foundation
import Vapor
import Redis

public struct QueueService: Service {
    let refreshInterval: TimeAmount
    let persistenceLayer: PersistenceLayer
    let persistenceKey: String
    let jobContext: JobContext
    let container: Container
    
    public func dispatch(job: Job) -> EventLoopFuture<Void> {
        return container.future()
    }
}
