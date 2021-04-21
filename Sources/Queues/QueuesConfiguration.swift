/// A `Service` to configure `Queues`s
public struct QueuesConfiguration {
    /// The number of seconds to wait before checking for the next job. Defaults to `1`
    public var refreshInterval: TimeAmount

    /// The key that stores the data about a job. Defaults to `vapor_queues`
    public var persistenceKey: String

    /// Supported options for number of job handling workers. 
    public enum WorkerCount: ExpressibleByIntegerLiteral {
        /// One worker per event loop.
        case `default`

        /// Specify a custom worker count.
        case custom(Int)

        /// See `ExpressibleByIntegerLiteral`.
        public init(integerLiteral value: Int) {
            self = .custom(value)
        }
    }

    /// Sets the number of workers used for handling jobs.
    public var workerCount: WorkerCount

    /// A logger
    public let logger: Logger

    // Arbitrary user info to be stored
    public var userInfo: [AnyHashable: Any]

    var jobs: [String: AnyJob]
    var scheduledJobsContainers: [ScheduleContainer]
    var scheduledJobs: [AnyScheduledJob] {
        scheduledJobsContainers.map { container in
            container.builders.map { builder in
                AnyScheduledJob(job: container.job, scheduler: builder)
            }
        }.reduce(into: [AnyScheduledJob]()) { $0 += $1 }
    }
    var notificationHooks: [JobEventDelegate]

    /// Creates an empty `JobsConfig`
    public init(
        refreshInterval: TimeAmount = .seconds(1),
        persistenceKey: String = "vapor_queues",
        workerCount: WorkerCount = .default,
        logger: Logger = .init(label: "codes.vapor.queues")
    ) {
        self.jobs = [:]
        self.scheduledJobsContainers = []
        self.logger = logger
        self.refreshInterval = refreshInterval
        self.persistenceKey = persistenceKey
        self.workerCount = workerCount
        self.userInfo = [:]
        self.notificationHooks = []
    }

    /// Adds a new `Job` to the queue configuration.
    /// This must be called on all `Job` objects before they can be run in a queue.
    ///
    /// - Parameter job: The `Job` to add.
    mutating public func add<J>(_ job: J)
    where J: Job
    {
        self.logger.trace("Adding job type: \(J.name)")
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
    /// - Parameter container: The `ScheduleContainer` to be used for schedule.
    mutating internal func schedule(container: ScheduleContainer) {
        self.logger.trace("Scheduling a container with job name \(container.job.name) and \(container.builders.count) builders.")
        self.scheduledJobsContainers.append(container)
    }

    /// Adds a notification hook that can receive status updates about jobs
    /// - Parameter hook: The `NotificationHook` object
    mutating public func add<N>(_ hook: N)
    where N: JobEventDelegate
    {
        self.logger.trace("Adding notification hook")
        self.notificationHooks.append(hook)
    }
}
