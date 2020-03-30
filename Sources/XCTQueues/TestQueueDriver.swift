import Queues
import Vapor

extension Application.Queues.Provider {
    public static var test: Self {
        .init {
            $0.queues.use(custom: TestQueuesDriver())
        }
    }
}

public struct TestQueuesDriver: QueuesDriver {
    public func makeQueue(with context: QueueContext) -> Queue {
        TestQueue(context: context)
    }
    
    public func shutdown() {
        // nothing
    }
}

extension Application.Queues {
    public final class TestQueueStorage {
        public var jobs: [JobIdentifier: JobData] = [:]
        public var queue: [JobIdentifier] = []
        
        /// Returns all the jobs of the specific `J` type
        public func all<J: Job>(_ job: J.Type) -> [JobIdentifier: JobData] {
            return jobs.filter { $1.jobName == J.name }
        }
        
        /// Returns the first job of the specific `J` type.
        public func first<J: Job>(_ job: J.Type) -> JobData? {
            return jobs.first(where: { $1.jobName == J.name })?.value
        }
        
        /// Checks whether a job of type `J` was dispatched
        public func contains<J: Job>(_ job: J.Type) -> Bool {
            return self.first(job) != nil
        }
    }
    
    struct TestQueueKey: StorageKey, LockKey {
        typealias Value = TestQueueStorage
    }
    
    public var test: TestQueueStorage {
        if let existing = self.application.storage[TestQueueKey.self] {
            return existing
        } else {
            let new = TestQueueStorage()
            self.application.storage[TestQueueKey.self] = new
            return new
        }
    }
}

public struct TestQueue: Queue {
    public let context: QueueContext
    
    public func get(_ id: JobIdentifier) -> EventLoopFuture<JobData> {
        return self.context.eventLoop.makeSucceededFuture(context.application.queues.test.jobs[id]!)
    }
    
    public func set(_ id: JobIdentifier, to data: JobData) -> EventLoopFuture<Void> {
        context.application.queues.test.jobs[id] = data
        return self.context.eventLoop.makeSucceededFuture(())
    }
    
    public func clear(_ id: JobIdentifier) -> EventLoopFuture<Void> {
        context.application.queues.test.jobs[id] = nil
        return self.context.eventLoop.makeSucceededFuture(())
    }
    
    public func pop() -> EventLoopFuture<JobIdentifier?> {
        return self.context.eventLoop.makeSucceededFuture(context.application.queues.test.queue.popLast())
    }
    
    public func push(_ id: JobIdentifier) -> EventLoopFuture<Void> {
        context.application.queues.test.queue.append(id)
        return self.context.eventLoop.makeSucceededFuture(())
    }
}
