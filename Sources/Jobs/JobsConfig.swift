import Foundation
import Vapor

/// A `Service` to configure `Job`s
public struct JobsConfig: Service {
    
    /// Decoder type
    internal typealias JobTypeDecoder = (Decoder) throws -> Job
    
    /// Type storage
    internal var storage: [String: JobTypeDecoder]
    
    /// Creates an empty `JobsConfig`
    public init() {
        storage = [:]
    }
    
    /// Adds a new `Job` to the queue configuration.
    /// This must be called on all `Job` objects before they can be run in a queue.
    ///
    /// - Parameter job: The `Job` to add.
    mutating public func add<J: Job>(_ job: J.Type) {
        storage[String(describing: job)] = J.init(from: )
    }
    
    
    /// Decodes a `JobData` container from a given decoder.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to use
    /// - Returns: A `JobData` container
    public func decode(from decoder: Decoder) throws -> JobData? {
        enum Keys: String, CodingKey {
            case key, type, data, maxRetryCount, id
        }
        
        let container = try decoder.container(keyedBy: Keys.self)
        let type = try container.decode(String.self, forKey: .type)
        let maxRetryCount = try container.decode(Int.self, forKey: .maxRetryCount)
        let key = try container.decode(String.self, forKey: .key)
        let id = try container.decode(String.self, forKey: .id)
        
        guard let jobType = storage[type] else { return nil }
        let job = try jobType(container.superDecoder(forKey: .data))
        
        return JobData(key: key, data: job, maxRetryCount: maxRetryCount, id: id)
    }
}
