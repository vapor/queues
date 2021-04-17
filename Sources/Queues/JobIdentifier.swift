import struct Foundation.UUID

/// An identifier for a job
public struct JobIdentifier: Hashable, Equatable {

    /// The string value of the ID
    public let string: String

    /// Creates a new id from a string
    public init(string: String) {
        self.string = string
    }

    /// Creates a new id with a default UUID value
    public init() {
        self.init(string: UUID().uuidString)
    }
}
