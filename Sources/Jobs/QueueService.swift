import Foundation
import Vapor

public struct QueueService: Service {
    //TODO: - Need to return EventLoopFuture<Void> here
    public func run(job: Job, configuration: QueueConfiguration) {
        
    }
}
