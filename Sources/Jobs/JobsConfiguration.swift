import Foundation
import Vapor

/// A `Service` to configure `Job`s
public struct JobsConfiguration {
    
    /// Type storage
    internal var storage: [String: AnyJob]
    
    /// Scheduled Job Storage
    internal var scheduledStorage: [AnyScheduledJob]
    
    /// A Logger object
    internal let logger: Logger
    
    /// Creates an empty `JobsConfig`
    public init() {
        storage = [:]
        scheduledStorage = []
        logger = Logger(label: "vapor.codes.jobs")
    }
    
    /// Adds a new `Job` to the queue configuration.
    /// This must be called on all `Job` objects before they can be run in a queue.
    ///
    /// - Parameter job: The `Job` to add.
    mutating public func add<J: Job>(_ job: J) {
        let key = String(describing: J.Data.self)
        if let existing = storage[key] {
            logger.warning("WARNING: A job is already registered with key \(key): \(existing)")
        }
        
        storage[key] = job
    }
    
    
    /// Schedules a new job for execution at a later date.
    ///
    ///     config.schedule(Cleanup())
    ///     .yearly()
    ///     .in(.may)
    ///     .on(23)
    ///     .at(.noon)
    ///
    /// - Parameter job: The `ScheduledJob` to be scheduled.
    mutating public func schedule<J: ScheduledJob>(_ job: J) -> ScheduleBuilder {
        let scheduler = ScheduleBuilder()
        let storage = AnyScheduledJob(job: job, scheduler: scheduler)
        scheduledStorage.append(storage)
        
        return scheduler
    }
    
    /// Returns the `AnyJob` for the string it was registered under
    ///
    /// - Parameter key: The key of the job
    /// - Returns: The `AnyJob`
    func make(for key: String) -> AnyJob? {
        return storage[key]
    }
}
