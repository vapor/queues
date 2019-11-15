import Foundation
import Vapor

/// A `Service` to configure `Job`s
public class JobsConfiguration: Service {
    /// Type storage
    internal var storage: [String: AnyJob]

    /// Scheduled Job Storage
    internal var scheduledStorage: [AnyScheduledJob]

    /// The number of seconds to wait before checking for the next job. Defaults to `1`
    public var refreshInterval: TimeAmount

    /// The key that stores the data about a job. Defaults to `vapor_jobs`
    public var persistenceKey: String

    public var userInfo: [AnyHashable: Any]

    /// Creates an empty `JobsConfig`
    public init(refreshInterval: TimeAmount = .seconds(1), persistenceKey: String = "vapor_jobs") {
        self.storage = [:]
        self.scheduledStorage = []
        self.refreshInterval = refreshInterval
        self.persistenceKey = persistenceKey
        self.userInfo = [:]
    }

    /// Adds a new `Job` to the queue configuration.
    /// This must be called on all `Job` objects before they can be run in a queue.
    ///
    /// - Parameter job: The `Job` to add.
    public func add<J>(_ job: J)
        where J: Job
    {
        let key = J.jobName
        if let existing = storage[key] {
            print("WARNING: A job is already registered with key \(key): \(existing)")
        }
        self.storage[key] = job
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
    @discardableResult
    internal func schedule<J>(_ job: J, builder: ScheduleBuilder = ScheduleBuilder()) -> ScheduleBuilder
        where J: ScheduledJob
    {
        let storage = AnyScheduledJob(job: job, scheduler: builder)
        self.scheduledStorage.append(storage)
        return builder
    }

    /// Returns the `AnyJob` for the string it was registered under
    ///
    /// - Parameter key: The key of the job
    /// - Returns: The `AnyJob`
    func make(for key: String) -> AnyJob? {
        return storage[key]
    }
}
