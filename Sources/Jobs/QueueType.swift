import Foundation

/// A specific queue that jobs are run on.
public struct QueueType {
    
    /// The name of the queue
    public let name: String
    
    /// Creates a new `QueueType`
    ///
    /// - Parameter name: The name of the `QueueType`
    public init(name: String) {
        self.name = name
    }
    
    /// Makes the name of the queue
    ///
    /// - Parameter persistanceKey: The base persistence key
    /// - Returns: A string of the queue's fully qualified name
    public func makeKey(with persistanceKey: String) -> String {
        return persistanceKey + "[\(name)]"
    }
}

/// Create a custom queue type by extending `QueueType` and adding a static variable with the custom name.
extension QueueType {
    /// The default queue that jobs are run on
    public static let `default` = QueueType(name: "default")
}
