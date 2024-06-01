import Queues
import Vapor
import NIOCore
import NIOConcurrencyHelpers

extension Application.Queues.Provider {
    public static var test: Self {
        .init {
            $0.queues.initializeTestStorage()
            return $0.queues.use(custom: TestQueuesDriver())
        }
    }
}

struct TestQueuesDriver: QueuesDriver {
    init() {}

    func makeQueue(with context: QueueContext) -> any Queue {
        TestQueue(_context: .init(context))
    }
    
    func shutdown() {
        // nothing
    }
}

extension Application.Queues {
    public final class TestQueueStorage: @unchecked Sendable {
        public var jobs: [JobIdentifier: JobData] = [:]
        public var queue: [JobIdentifier] = []

        /// Returns all jobs in the queue of the specific `J` type.
        public func all<J>(_ job: J.Type) -> [J.Payload]
            where J: Job
        {
            let filteredJobIds = jobs.filter { $1.jobName == J.name }.map { $0.0 }

            return queue
                .filter { filteredJobIds.contains($0) }
                .compactMap { jobs[$0] }
                .compactMap { try? J.parsePayload($0.payload) }
        }

        /// Returns the first job in the queue of the specific `J` type.
        public func first<J>(_ job: J.Type) -> J.Payload?
            where J: Job
        {
            let filteredJobIds = jobs.filter { $1.jobName == J.name }.map { $0.0 }
            guard
                let queueJob = queue.first(where: { filteredJobIds.contains($0) }),
                let jobData = jobs[queueJob]
                else {
                    return nil
            }
            
            return try? J.parsePayload(jobData.payload)
        }
        
        /// Checks whether a job of type `J` was dispatched to queue
        public func contains<J>(_ job: J.Type) -> Bool
            where J: Job
        {
            return first(job) != nil
        }
    }
    
    struct TestQueueKey: StorageKey, LockKey {
        typealias Value = TestQueueStorage
    }
    
    public var test: TestQueueStorage {
        self.application.storage[TestQueueKey.self]!
    }

    func initializeTestStorage() {
        self.application.storage[TestQueueKey.self] = .init()
    }
}

struct TestQueue: Queue {
    let _context: NIOLockedValueBox<QueueContext>
    var context: QueueContext { self._context.withLockedValue { $0 } }
    
    func get(_ id: JobIdentifier) -> EventLoopFuture<JobData> {
        self._context.withLockedValue { context in
            context.eventLoop.makeSucceededFuture(context.application.queues.test.jobs[id]!)
        }
    }
    
    func set(_ id: JobIdentifier, to data: JobData) -> EventLoopFuture<Void> {
        self._context.withLockedValue { context in
            context.application.queues.test.jobs[id] = data
            return context.eventLoop.makeSucceededVoidFuture()
        }
    }
    
    func clear(_ id: JobIdentifier) -> EventLoopFuture<Void> {
        self._context.withLockedValue { context in
            context.application.queues.test.jobs[id] = nil
            return context.eventLoop.makeSucceededVoidFuture()
        }
    }
    
    func pop() -> EventLoopFuture<JobIdentifier?> {
        self._context.withLockedValue { context in
            let last = context.application.queues.test.queue.popLast()
            return context.eventLoop.makeSucceededFuture(last)
        }
    }
    
    func push(_ id: JobIdentifier) -> EventLoopFuture<Void> {
        self._context.withLockedValue { context in
            context.application.queues.test.queue.append(id)
            return context.eventLoop.makeSucceededVoidFuture()
        }
    }
}
