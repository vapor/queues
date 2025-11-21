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
        var staleJobTimeout: TimeAmount = .seconds(300)  // 5 minutes default (like Sidekiq)
        var staleJobRecoveryInterval: TimeAmount = .seconds(15)  // 15 seconds default (like Sidekiq Beat)
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

    /// The timeout for considering a job in the processing queue as stale and eligible for recovery.
    /// Defaults to 5 minutes (300 seconds). Jobs older than this timeout will be requeued on worker startup.
    public var staleJobTimeout: TimeAmount {
        get { self.dataBox.withLockedValue { $0.staleJobTimeout } }
        set { self.dataBox.withLockedValue { $0.staleJobTimeout = newValue } }
    }

    /// The interval at which stale jobs are checked and recovered. Defaults to 15 seconds (like Sidekiq Beat).
    /// This periodic check ensures that stale jobs are recovered even if no workers restart.
    public var staleJobRecoveryInterval: TimeAmount {
        get { self.dataBox.withLockedValue { $0.staleJobRecoveryInterval } }
        set { self.dataBox.withLockedValue { $0.staleJobRecoveryInterval = newValue } }
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

    /// Creates an empty ``QueuesConfiguration``.
    public init(
        refreshInterval: TimeAmount = .seconds(1),
        persistenceKey: String = "vapor_queues",
        workerCount: WorkerCount = .default,
        staleJobTimeout: TimeAmount = .seconds(300),  // 5 minutes default
        staleJobRecoveryInterval: TimeAmount = .seconds(15),  // 15 seconds default (like Sidekiq Beat)
        logger: Logger = .init(label: "codes.vapor.queues")
    ) {
        self.logger = logger
        self.refreshInterval = refreshInterval
        self.persistenceKey = persistenceKey
        self.workerCount = workerCount
        self.staleJobTimeout = staleJobTimeout
        self.staleJobRecoveryInterval = staleJobRecoveryInterval
    }

    /// Adds a new ``Job`` to the queue configuration.
    ///
    /// This must be called on all ``Job`` objects before they can be run in a queue.
    ///
    /// - Parameter job: The ``Job`` to add.
    mutating public func add<J: Job>(_ job: J) {
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
    /// - Parameters:
    ///   - job: The ``ScheduledJob`` to schedule.
    ///   - builder: A ``ScheduleBuilder`` to use for scheduling.
    /// - Returns: The passed-in ``ScheduleBuilder``.
    mutating func schedule(_ job: some ScheduledJob, builder: ScheduleBuilder = .init()) -> ScheduleBuilder {
        self.logger.trace("Scheduling job", metadata: ["job-name": "\(job.name)"])
        self.scheduledJobs.append(AnyScheduledJob(job: job, scheduler: builder))
        return builder
    }

    /// Adds a notification hook that can receive status updates about jobs
    ///
    /// - Parameter hook: A ``JobEventDelegate`` to register.
    mutating public func add(_ hook: some JobEventDelegate) {
        self.logger.trace("Adding notification hook")
        self.notificationHooks.append(hook)
    }
}
