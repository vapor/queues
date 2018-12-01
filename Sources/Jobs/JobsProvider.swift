import Foundation
import Vapor

public struct JobsProvider: Provider {
    
    /// In seconds
    let refreshInterval: Int
    
    public init(refreshInterval: Int = 1) {
        self.refreshInterval = refreshInterval
    }
    
    public func register(_ services: inout Services) throws {
        services.register { _ -> QueueService in
            return QueueService()
        }
    }
    
    public func didBoot(_ container: Container) throws -> EventLoopFuture<Void> {
        return container.future()
    }
}
