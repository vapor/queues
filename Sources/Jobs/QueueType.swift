import Foundation

public struct QueueType {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public func makeKey(with persistanceKey: String) -> String {
        return persistanceKey + "[\(name)]"
    }
}

extension QueueType {
    public static let `default` = QueueType(name: "default")
}
