import struct Foundation.UUID

public struct JobIdentifier: Hashable, Equatable {
    public let string: String
    
    public init(string: String) {
        self.string = string
    }
    
    public init() {
        self.init(string: UUID().uuidString)
    }
}
