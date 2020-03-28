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

public struct TestQueue: Queue {
    public static var queue: [JobIdentifier] = []
    public static var jobs: [JobIdentifier: JobData] = [:]
    public static var lock: Lock = .init()
    
    public let context: QueueContext
    
    public func get(_ id: JobIdentifier) -> EventLoopFuture<JobData> {
        TestQueue.lock.lock()
        defer { TestQueue.lock.unlock() }
        return self.context.eventLoop.makeSucceededFuture(TestQueue.jobs[id]!)
    }
    
    public func set(_ id: JobIdentifier, to data: JobData) -> EventLoopFuture<Void> {
        TestQueue.lock.lock()
        defer { TestQueue.lock.unlock() }
        TestQueue.jobs[id] = data
        return self.context.eventLoop.makeSucceededFuture(())
    }
    
    public func clear(_ id: JobIdentifier) -> EventLoopFuture<Void> {
        TestQueue.lock.lock()
        defer { TestQueue.lock.unlock() }
        TestQueue.jobs[id] = nil
        return self.context.eventLoop.makeSucceededFuture(())
    }
    
    public func pop() -> EventLoopFuture<JobIdentifier?> {
        TestQueue.lock.lock()
        defer { TestQueue.lock.unlock() }
        return self.context.eventLoop.makeSucceededFuture(TestQueue.queue.popLast())
    }
    
    public func push(_ id: JobIdentifier) -> EventLoopFuture<Void> {
        TestQueue.lock.lock()
        defer { TestQueue.lock.unlock() }
        TestQueue.queue.append(id)
        return self.context.eventLoop.makeSucceededFuture(())
    }
}
