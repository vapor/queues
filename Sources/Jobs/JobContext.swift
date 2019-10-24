import Foundation
import Vapor

/// A simple wrapper to hold job context and services.
public struct JobContext {
    /// Storage for the wrapper.
    public var userInfo: [String: Any]
    
    /// Event loop for jobs to access
    public var eventLoopGroup: EventLoopGroup
    
    /// Creates an empty `JobContext`
    public init(eventLoopGroup: EventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
        self.userInfo = [:]
    }
}
