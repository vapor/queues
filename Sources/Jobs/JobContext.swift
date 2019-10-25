import Foundation
import Vapor

/// A simple wrapper to hold job context and services.
public struct JobContext {
    /// Storage for the wrapper.
    public var userInfo: [AnyHashable: Any]
    
    public let eventLoop: EventLoop
    
    /// Creates an empty `JobContext`
    public init(userInfo: [AnyHashable: Any] = [:], on eventLoop: EventLoop) {
        self.eventLoop = eventLoop
        self.userInfo = [:]
    }
}
