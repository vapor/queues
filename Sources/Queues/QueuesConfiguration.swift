import ConsoleKitTerminal
import Logging
import NIOCore
import NIOConcurrencyHelpers

/// Configuration parameters for the Queues module as a whole.
public struct QueuesConfiguration: Sendable {
    private struct DataBox: Sendable {
        var refreshInterval: TimeAmount = .seconds(1)
        var persistenceKey: String = "vapor_queues"
        var workerCount: WorkerCount = .default
        var userInfo: [AnySendableHashable: any Sendable] = [:]
        
        var jobs: [String: any AnyJob] = [:]
        var scheduledJobs: [AnyScheduledJob] = []
        var notificationHooks: [any JobEventDelegate] = []
    }
    
    private let dataBox: NIOLockedValueBox<DataBox> = .init(.init())
    
    /// The number of seconds to wait before checking for the next job. Defaults to `1`
    public var refreshInterval: TimeAmount {
        get { self.dataBox.withLockedValue { $0.refreshInterval } }
        set { self.dataBox.withLockedValue { $0.refreshInterval = newValue } }
    }

    /// The key that stores the data about a job. Defaults to `vapor_queues`
    public var persistenceKey: String {
        get { self.dataBox.withLockedValue { $0.persistenceKey } }
        set { self.dataBox.withLockedValue { $0.persistenceKey = newValue } }
    }

    /// Supported options for number of job handling workers. 
    public enum WorkerCount: ExpressibleByIntegerLiteral, Sendable {
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
    public var workerCount: WorkerCount {
        get { self.dataBox.withLockedValue { $0.workerCount } }
        set { self.dataBox.withLockedValue { $0.workerCount = newValue } }
    }
    
    /// A logger
    public let logger: Logger
    
    // Arbitrary user info to be stored
    public var userInfo: [AnySendableHashable: any Sendable] {
        get { self.dataBox.withLockedValue { $0.userInfo } }
        set { self.dataBox.withLockedValue { $0.userInfo = newValue } }
    }
    
    var jobs: [String: any AnyJob] {
        get { self.dataBox.withLockedValue { $0.jobs } }
        set { self.dataBox.withLockedValue { $0.jobs = newValue } }
    }
    
    var scheduledJobs: [AnyScheduledJob] {
        get { self.dataBox.withLockedValue { $0.scheduledJobs } }
        set { self.dataBox.withLockedValue { $0.scheduledJobs = newValue } }
    }
    
    var notificationHooks: [any JobEventDelegate] {
        get { self.dataBox.withLockedValue { $0.notificationHooks } }
        set { self.dataBox.withLockedValue { $0.notificationHooks = newValue } }
    }
    
    /// Creates an empty `JobsConfig`
    public init(
        refreshInterval: TimeAmount = .seconds(1),
        persistenceKey: String = "vapor_queues",
        workerCount: WorkerCount = .default,
        logger: Logger = .init(label: "codes.vapor.queues")
    ) {
        self.logger = logger
        self.refreshInterval = refreshInterval
        self.persistenceKey = persistenceKey
        self.workerCount = workerCount
    }
    
    /// Adds a new `Job` to the queue configuration.
    /// This must be called on all `Job` objects before they can be run in a queue.
    ///
    /// - Parameter job: The `Job` to add.
    mutating public func add<J>(_ job: J)
        where J: Job
    {
        self.logger.trace("Adding job type", metadata: ["name": "\(J.name)"])
        if let existing = self.jobs[J.name] {
            self.logger.warning("Job type is already registered", metadata: ["name": "\(J.name)", "existing": "\(existing)"])
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
        self.logger.trace("Scheduling job", metadata: ["job-name": "\(job.name)"])
        return builder
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
