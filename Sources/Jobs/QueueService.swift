import Foundation
import Vapor

public struct QueueService: Service {
    let refreshInterval: TimeAmount
    let persistenceLayer: JobsPersistenceLayer
    let persistenceKey: String
    
    public func dispatch<J: Job>(job: J) throws -> EventLoopFuture<Void> {
        return try persistenceLayer.set(key: persistenceKey, job: job).transform(to: ())
    }
}
