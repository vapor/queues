/// A `Service` to configure `Job`s
public struct JobsConfiguration {
    /// The number of seconds to wait before checking for the next job. Defaults to `1`
    public var refreshInterval: TimeAmount

    /// The key that stores the data about a job. Defaults to `vapor_jobs`
    public var persistenceKey: String
    
    /// A logger
    public let logger: Logger
    
    // Arbitrary user info to be stored
    public var userInfo: [AnyHashable: Any]
    
    var jobs: [String: AnyJob]
    var scheduledJobs: [AnyScheduledJob]
    
    /// Creates an empty `JobsConfig`
    public init(
        refreshInterval: TimeAmount = .seconds(1),
        persistenceKey: String = "vapor_jobs",
        logger: Logger = .init(label: "codes.vapor.jobs")
    ) {
        self.jobs = [:]
        self.scheduledJobs = []
        self.logger = logger
        self.refreshInterval = refreshInterval
        self.persistenceKey = persistenceKey
        self.userInfo = [:]
    }
    
    /// Adds a new `Job` to the queue configuration.
    /// This must be called on all `Job` objects before they can be run in a queue.
    ///
    /// - Parameter job: The `Job` to add.
    mutating public func add<J>(_ job: J)
        where J: Job
    {
        if let existing = self.jobs[J.name] {
            self.logger.warning("A job is already registered with key \(J.name): \(existing)")
        }
        self.jobs[J.name] = job
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
    mutating internal func schedule<J>(_ job: J, builder: ScheduleBuilder = ScheduleBuilder()) -> ScheduleBuilder
        where J: ScheduledJob
    {
        let storage = AnyScheduledJob(job: job, scheduler: builder)
        self.scheduledJobs.append(storage)
        return builder
    }
}
