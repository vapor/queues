import NIOConcurrencyHelpers
import NIOCore
import Queues
import Vapor

extension Application.Queues.Provider {
    public static var test: Self {
        .init {
            $0.queues.initializeTestStorage()
            return $0.queues.use(custom: TestQueuesDriver())
        }
    }

    public static var asyncTest: Self {
        .init {
            $0.queues.initializeAsyncTestStorage()
            return $0.queues.use(custom: AsyncTestQueuesDriver())
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

struct AsyncTestQueuesDriver: QueuesDriver {
    init() {}
    func makeQueue(with context: QueueContext) -> any Queue { AsyncTestQueue(_context: .init(context)) }
    func shutdown() {}
}

extension Application.Queues {
    public final class TestQueueStorage: Sendable {
        private struct Box: Sendable {
            var jobs: [JobIdentifier: JobData] = [:]
            var queue: [JobIdentifier] = []
        }

        private let box = NIOLockedValueBox<Box>(.init())

        public var jobs: [JobIdentifier: JobData] {
            get { self.box.withLockedValue { $0.jobs } }
            set { self.box.withLockedValue { $0.jobs = newValue } }
        }

        public var queue: [JobIdentifier] {
            get { self.box.withLockedValue { $0.queue } }
            set { self.box.withLockedValue { $0.queue = newValue } }
        }

        /// Returns the payloads of all jobs in the queue having type `J`.
        public func all<J: Job>(_: J.Type) -> [J.Payload] {
            let filteredJobIds = self.jobs.filter { $1.jobName == J.name }.map { $0.0 }

            return self.queue
                .filter { filteredJobIds.contains($0) }
                .compactMap { self.jobs[$0] }
                .compactMap { try? J.parsePayload($0.payload) }
        }

        /// Returns the payload of the first job in the queue having type `J`.
        public func first<J: Job>(_: J.Type) -> J.Payload? {
            let filteredJobIds = self.jobs.filter { $1.jobName == J.name }.map { $0.0 }

            guard let queueJob = self.queue.first(where: { filteredJobIds.contains($0) }), let jobData = self.jobs[queueJob] else {
                return nil
            }
            return try? J.parsePayload(jobData.payload)
        }

        /// Checks whether a job of type `J` was dispatched to queue
        public func contains<J: Job>(_ job: J.Type) -> Bool {
            self.first(job) != nil
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

    struct AsyncTestQueueKey: StorageKey, LockKey {
        typealias Value = TestQueueStorage
    }

    public var asyncTest: TestQueueStorage {
        self.application.storage[AsyncTestQueueKey.self]!
    }

    func initializeAsyncTestStorage() {
        self.application.storage[AsyncTestQueueKey.self] = .init()
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

struct AsyncTestQueue: AsyncQueue {
    let _context: NIOLockedValueBox<QueueContext>
    var context: QueueContext { self._context.withLockedValue { $0 } }

    func get(_ id: JobIdentifier) async throws -> JobData { self._context.withLockedValue { $0.application.queues.asyncTest.jobs[id]! } }
    func set(_ id: JobIdentifier, to data: JobData) async throws { self._context.withLockedValue { $0.application.queues.asyncTest.jobs[id] = data } }
    func clear(_ id: JobIdentifier) async throws { self._context.withLockedValue { $0.application.queues.asyncTest.jobs[id] = nil } }
    func pop() async throws -> JobIdentifier? { self._context.withLockedValue { $0.application.queues.asyncTest.queue.popLast() } }
    func push(_ id: JobIdentifier) async throws { self._context.withLockedValue { $0.application.queues.asyncTest.queue.append(id) } }
}
