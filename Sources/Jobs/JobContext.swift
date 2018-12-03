import Foundation
import Vapor

public struct JobContext: Service {
    public var userInfo: [String: Any]
    
    public init() {
        self.userInfo = [:]
    }
}

struct TestingService: Service { }

extension JobContext {
    var testingService: TestingService? {
        get {
            return userInfo[String(describing: self)] as? TestingService
        }
        set {
            userInfo[String(describing: self)] = newValue
        }
    }
}
