/// A specific queue that jobs are run on.
public struct QueueName {
    /// The default queue that jobs are run on
    public static let `default` = Self(string: "default")

    /// The name of the queue
    public let string: String

    /// Creates a new ``QueueName``
    ///
    /// - Parameter name: The name of the queue
    public init(string: String) {
        self.string = string
    }

    /// Makes the name of the queue
    ///
    /// - Parameter persistenceKey: The base persistence key
    /// - Returns: A string of the queue's fully qualified name
    public func makeKey(with persistenceKey: String) -> String {
        "\(persistenceKey)[\(self.string)]"
    }
}
