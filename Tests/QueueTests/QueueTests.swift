import Queues
import Vapor
import XCTVapor
import XCTQueues
@testable import Vapor

final class QueueTests: XCTestCase {
    func testVaporIntegration() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        app.queues.use(.test)
        
        TestQueue.reset()
        
        let promise = app.eventLoopGroup.next().makePromise(of: String.self)
        app.queues.add(Foo(promise: promise))
        
        app.get("foo") { req in
            req.queue.dispatch(Foo.self, .init(foo: "bar"))
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
        
        try app.queues.queue.worker.run().wait()
        XCTAssertEqual(TestQueue.queue.count, 0)
        XCTAssertEqual(TestQueue.jobs.count, 0)
        
        try XCTAssertEqual(promise.futureResult.wait(), "bar")
    }
    
    func testAssert() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        app.queues.use(.test)
        
        app.queues.add(DummyJob())
        app.queues.add(SecondDummyJob())
        
        try app.queues.queue.dispatch(SecondDummyJob.self, [:]).wait()
        try app.queues.queue.dispatch(DummyJob.self, [:]).wait()
        
        XCTAssertDispatched(DummyJob.self, app: app)
        XCTAssertDispatched(SecondDummyJob.self, app: app)
    }

    func testScheduleBuilderAPI() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        // yearly
        app.queues.schedule(Cleanup())
            .yearly()
            .in(.may)
            .on(23)
            .at(.noon)

        // monthly
        app.queues.schedule(Cleanup())
            .monthly()
            .on(15)
            .at(.midnight)

        // weekly
        app.queues.schedule(Cleanup())
            .weekly()
            .on(.monday)
            .at("3:13am")

        // daily
        app.queues.schedule(Cleanup())
            .daily()
            .at("5:23pm")

        // daily 2
        app.queues.schedule(Cleanup())
            .daily()
            .at(5, 23, .pm)

        // daily 3
        app.queues.schedule(Cleanup())
            .daily()
            .at(17, 23)

        // hourly
        app.queues.schedule(Cleanup())
            .hourly()
            .at(30)
    }
    
    func testRepeatingScheduledJob() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        XCTAssertEqual(TestingScheduledJob.count, 0)
        app.queues.schedule(TestingScheduledJob()).everySecond()
        try app.queues.startScheduledJobs()
        
        let promise = app.eventLoopGroup.next().makePromise(of: Void.self)
        app.eventLoopGroup.next().scheduleTask(in: .seconds(5)) { () -> Void in
            XCTAssert(TestingScheduledJob.count > 4)
            promise.succeed(())
        }
        
        try promise.futureResult.wait()
    }
}

extension TestQueue {
    static func reset() {
        TestQueue.lock.lock()
        defer { TestQueue.lock.unlock() }
        TestQueue.queue.removeAll()
        TestQueue.jobs.removeAll()
    }
}

struct DummyJob: Job {
    typealias Payload = [String: String]
    func dequeue(_ context: QueueContext, _ payload: [String: String]) -> EventLoopFuture<Void> {
        return context.eventLoop.makeSucceededFuture(())
    }
}

struct SecondDummyJob: Job {
    typealias Payload = [String: String]
    func dequeue(_ context: QueueContext, _ payload: [String: String]) -> EventLoopFuture<Void> {
        return context.eventLoop.makeSucceededFuture(())
    }
}

struct TestingScheduledJob: ScheduledJob {
    static var count = 0
    
    func run(context: QueueContext) -> EventLoopFuture<Void> {
        TestingScheduledJob.count += 1
        return context.eventLoop.future()
    }
}

extension ByteBuffer {
    var string: String {
        return .init(decoding: self.readableBytesView, as: UTF8.self)
    }
}


struct Foo: Job {
    let promise: EventLoopPromise<String>
    
    struct Data: Codable {
        var foo: String
    }
    
    func dequeue(_ context: QueueContext, _ data: Data) -> EventLoopFuture<Void> {
        self.promise.succeed(data.foo)
        return context.eventLoop.makeSucceededFuture(())
    }
    
    func error(_ context: QueueContext, _ error: Error, _ data: Data) -> EventLoopFuture<Void> {
        self.promise.fail(error)
        return context.eventLoop.makeSucceededFuture(())
    }
}
