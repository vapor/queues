import Foundation
import Vapor

public struct JobsProvider: Provider {
    let refreshInterval: TimeAmount
    
    public init(refreshInterval: TimeAmount = .seconds(1)) {
        self.refreshInterval = refreshInterval
    }
    
    public func register(_ services: inout Services) throws {
        services.register { _ -> QueueService in
            return QueueService(refreshInterval: self.refreshInterval)
        }
    }
    
    public func didBoot(_ container: Container) throws -> EventLoopFuture<Void> {
        return container.future()
    }
}
