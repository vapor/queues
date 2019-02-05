import Foundation
import Vapor

/// A `Service` to configure `Job`s
public struct JobsConfig: Service {
    
    /// Decoder type
    internal typealias JobTypeDecoder = (Decoder) throws -> JobData
    
    /// Type storage
    internal var storage: [String: AnyJob]
    
    /// Creates an empty `JobsConfig`
    public init() {
        storage = [:]
    }
    
    /// Adds a new `Job` to the queue configuration.
    /// This must be called on all `Job` objects before they can be run in a queue.
    ///
    /// - Parameter job: The `Job` to add.
    mutating public func add(_ job: AnyJob) throws {
        storage[String(describing: job)] = job
    }
    
    
    /// Returns the `AnyJob` for the string it was registered under
    ///
    /// - Parameter key: The key of the job
    /// - Returns: The `AnyJob`
    func make(for key: String) -> AnyJob? {
        return storage[key]
    }
}
