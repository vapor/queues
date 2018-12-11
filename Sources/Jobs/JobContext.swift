import Foundation
import Vapor

/// A simple wrapper to hold job context and services.
public struct JobContext: Service {
    
    /// Storage for the wrapper.
    public var userInfo: [String: Any]
    
    /// Creates an empty `JobContext`
    public init() {
        self.userInfo = [:]
    }
}
