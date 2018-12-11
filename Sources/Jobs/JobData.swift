import Foundation


/// Holds information about the Job that is to be encoded to the persistence store.
public struct JobData: Encodable {
    
    /// The persistence key for the backing store.
    var key: String
    
    /// The `Job` to be encoded.
    var data: Job
    
    /// The maxRetryCount for the `Job`.
    var maxRetryCount: Int
    
    /// Creates a new `JobData` holding object
    ///
    /// - Parameters:
    ///   - key: See `key`
    ///   - data: See `data`
    ///   - maxRetryCount: See `maxRetryCount`
    public init(key: String, data: Job, maxRetryCount: Int) {
        self.key = key
        self.data = data
        self.maxRetryCount = maxRetryCount
    }
    
    /// Coding keys for the `JobData` encodable object
    ///
    /// - key: See `key`
    /// - type: The concrete type of the `Job`
    /// - data: See `data`
    /// - maxRetryCount: See `maxRetryCount`
    enum CodingKeys: String, CodingKey {
        case key, type, data, maxRetryCount
    }
    
    /// Encodes a new `JobData` object from a given `Encoder`.
    ///
    /// - Parameter encoder: The specified `Encoder` to use.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.key, forKey: .key)
        try container.encode(self.maxRetryCount, forKey: .maxRetryCount)
        let typeString = String(describing: type(of: self.data))
        try container.encode(typeString, forKey: .type)
        
        let superEncoder = container.superEncoder(forKey: .data)
        try self.data.encode(to: superEncoder)
    }
}
