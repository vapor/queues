import Queues
import Vapor
import XCTVapor
@testable import Vapor

final class QueueTests: XCTestCase {
    func testVaporIntegration() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        app.jobs.use(custom: TestDriver())
        
        let promise = app.eventLoopGroup.next().makePromise(of: String.self)
        app.jobs.add(Foo(promise: promise))
        
        app.get("foo") { req in
            req.jobs.dispatch(Foo.self, .init(foo: "bar"))
                .map { "done" }
        }
        
        try app.testable().test(.GET, "foo") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }
        
        XCTAssertEqual(TestQueue.queue.count, 1)
        XCTAssertEqual(TestQueue.jobs.count, 1)
        let job = TestQueue.jobs[TestQueue.queue[0]]!
        XCTAssertEqual(job.jobName, "Foo")
        XCTAssertEqual(job.maxRetryCount, 0)
        
        try app.jobs.queue.worker.run().wait()
        XCTAssertEqual(TestQueue.queue.count, 0)
        XCTAssertEqual(TestQueue.jobs.count, 0)
        
        try XCTAssertEqual(promise.futureResult.wait(), "bar")
    }

    func testScheduleBuilderAPI() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        // yearly
        app.jobs.schedule(Cleanup())
            .yearly()
            .in(.may)
            .on(23)
            .at(.noon)

        // monthly
        app.jobs.schedule(Cleanup())
            .monthly()
            .on(15)
            .at(.midnight)

        // weekly
        app.jobs.schedule(Cleanup())
            .weekly()
            .on(.monday)
            .at("3:13am")

        // daily
        app.jobs.schedule(Cleanup())
            .daily()
            .at("5:23pm")

        // daily 2
        app.jobs.schedule(Cleanup())
            .daily()
            .at(5, 23, .pm)

        // daily 3
        app.jobs.schedule(Cleanup())
            .daily()
            .at(17, 23)

        // hourly
        app.jobs.schedule(Cleanup())
            .hourly()
            .at(30)
    }
    
    func testRepeatingScheduledJob() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        XCTAssertEqual(TestingScheduledJob.count, 0)
        app.jobs.schedule(TestingScheduledJob()).everySecond()
        try JobsCommand(application: app, scheduled: true).startScheduledJobs()
        
        let promise = app.eventLoopGroup.next().makePromise(of: Void.self)
        app.eventLoopGroup.next().scheduleTask(in: .seconds(5)) { () -> Void in
            XCTAssert(TestingScheduledJob.count > 4)
            promise.succeed(())
        }
        
        try promise.futureResult.wait()
    }
}

struct TestingScheduledJob: ScheduledJob {
    static var count = 0
    
    func run(context: JobContext) -> EventLoopFuture<Void> {
        TestingScheduledJob.count += 1
        return context.eventLoop.future()
    }
}

extension ByteBuffer {
    var string: String {
        return .init(decoding: self.readableBytesView, as: UTF8.self)
    }
}

struct TestDriver: JobsDriver {
    func makeQueue(with context: JobContext) -> JobsQueue {
        TestQueue(context: context)
    }
    
    func shutdown() {
        // nothing
    }
}

struct TestQueue: JobsQueue {
    static var queue: [JobIdentifier] = []
    static var jobs: [JobIdentifier: JobData] = [:]
    static var lock: Lock = .init()
    
    let context: JobContext
    
    func get(_ id: JobIdentifier) -> EventLoopFuture<JobData> {
        TestQueue.lock.lock()
        defer { TestQueue.lock.unlock() }
        return self.context.eventLoop.makeSucceededFuture(TestQueue.jobs[id]!)
    }
    
    func set(_ id: JobIdentifier, to data: JobData) -> EventLoopFuture<Void> {
        TestQueue.lock.lock()
        defer { TestQueue.lock.unlock() }
        TestQueue.jobs[id] = data
        return self.context.eventLoop.makeSucceededFuture(())
    }
    
    func clear(_ id: JobIdentifier) -> EventLoopFuture<Void> {
        TestQueue.lock.lock()
        defer { TestQueue.lock.unlock() }
        TestQueue.jobs[id] = nil
        return self.context.eventLoop.makeSucceededFuture(())
    }
    
    func pop() -> EventLoopFuture<JobIdentifier?> {
        TestQueue.lock.lock()
        defer { TestQueue.lock.unlock() }
        return self.context.eventLoop.makeSucceededFuture(TestQueue.queue.popLast())
    }
    
    func push(_ id: JobIdentifier) -> EventLoopFuture<Void> {
        TestQueue.lock.lock()
        defer { TestQueue.lock.unlock() }
        TestQueue.queue.append(id)
        return self.context.eventLoop.makeSucceededFuture(())
    }
}

struct Foo: Job {
    let promise: EventLoopPromise<String>
    
    struct Data: Codable {
        var foo: String
    }
    
    func dequeue(_ context: JobContext, _ data: Data) -> EventLoopFuture<Void> {
        self.promise.succeed(data.foo)
        return context.eventLoop.makeSucceededFuture(())
    }
    
    func error(_ context: JobContext, _ error: Error, _ data: Data) -> EventLoopFuture<Void> {
        self.promise.fail(error)
        return context.eventLoop.makeSucceededFuture(())
    }
}
