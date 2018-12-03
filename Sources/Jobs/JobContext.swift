import Foundation
import Vapor

public struct JobContext: Service {
    public var userInfo: [String: Any]
    
    public init() {
        self.userInfo = [:]
    }
}
