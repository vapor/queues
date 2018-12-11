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
    
    
    /// Decodes a `Job` from a given type and decoder.
    ///
    /// - Parameters:
    ///   - jobType: The type of string. Retrieved via `String(describing: job)`
    ///   - decoder: The decoder to use
    /// - Returns: A `Job`
    public func decode(jobType: String, from decoder: Decoder) throws -> Job {
        guard let jobDecoder = storage[jobType] else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown job type \(jobType)"))
        }
        
        return try jobDecoder(decoder)
    }
}
