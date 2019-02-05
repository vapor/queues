import Foundation
import Vapor

/// A `Service` to configure `Job`s
public struct JobsConfig: Service {
    
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
    mutating public func add<J: Job>(_ job: J) {
        storage[String(describing: J.Data.self)] = job
    }
    
    
    /// Returns the `AnyJob` for the string it was registered under
    ///
    /// - Parameter key: The key of the job
    /// - Returns: The `AnyJob`
    func make(for key: String) -> AnyJob? {
        return storage[key]
    }
}
