import Foundation

/// A specific queue that jobs are run on.
public struct JobsQueue {
    /// The default queue that jobs are run on
    public static let `default` = JobsQueue(name: "default")

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
        return persistanceKey + "[\(self.name)]"
    }
}
