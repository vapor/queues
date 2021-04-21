import Queues
import Vapor

extension Application.Queues.Provider {
    public static var test: Self {
        .init {
            $0.queues.initializeTestStorage()
            return $0.queues.use(custom: TestQueuesDriver())
        }
    }
}

struct TestQueuesDriver: QueuesDriver {
    let lock: Lock

    init() {
        self.lock = .init()
    }

    func makeQueue(with context: QueueContext) -> Queue {
        TestQueue(lock: self.lock, context: context)
    }

    func shutdown() {
        // nothing
    }
}

extension Application.Queues {
    public final class TestQueueStorage {
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
    let lock: Lock
    let context: QueueContext

    func get(_ id: JobIdentifier) -> EventLoopFuture<JobData> {
        self.lock.lock()
        defer { self.lock.unlock() }

        return self.context.eventLoop.makeSucceededFuture(
            self.context.application.queues.test.jobs[id]!
        )
    }

    func set(_ id: JobIdentifier, to data: JobData) -> EventLoopFuture<Void> {
        self.lock.lock()
        defer { self.lock.unlock() }

        self.context.application.queues.test.jobs[id] = data
        return self.context.eventLoop.makeSucceededFuture(())
    }

    func clear(_ id: JobIdentifier) -> EventLoopFuture<Void> {
        self.lock.lock()
        defer { self.lock.unlock() }

        self.context.application.queues.test.jobs[id] = nil
        return self.context.eventLoop.makeSucceededFuture(())
    }

    func pop() -> EventLoopFuture<JobIdentifier?> {
        self.lock.lock()
        defer { self.lock.unlock() }

        let last = context.application.queues.test.queue.popLast()
        return self.context.eventLoop.makeSucceededFuture(last)
    }

    func push(_ id: JobIdentifier) -> EventLoopFuture<Void> {
        self.lock.lock()
        defer { self.lock.unlock() }

        self.context.application.queues.test.queue.append(id)
        return self.context.eventLoop.makeSucceededFuture(())
    }
}
