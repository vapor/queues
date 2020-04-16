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
        
        let promise = app.eventLoopGroup.next().makePromise(of: String.self)
        app.queues.add(Foo(promise: promise))
        
        app.get("foo") { req in
            req.queue.dispatch(Foo.self, .init(foo: "bar"))
                .map { _ in "done" }
        }
        
        try app.testable().test(.GET, "foo") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }
        
        XCTAssertEqual(app.queues.test.queue.count, 1)
        XCTAssertEqual(app.queues.test.jobs.count, 1)
        let job = app.queues.test.first(Foo.self)
        XCTAssert(app.queues.test.contains(Foo.self))
        XCTAssertNotNil(job)
        XCTAssertEqual(job!.foo, "bar")
        
        try app.queues.queue.worker.run().wait()
        XCTAssertEqual(app.queues.test.queue.count, 0)
        XCTAssertEqual(app.queues.test.jobs.count, 0)
        
        try XCTAssertEqual(promise.futureResult.wait(), "bar")
    }

    func testSettingCustomId() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        app.queues.use(.test)
        
        let promise = app.eventLoopGroup.next().makePromise(of: String.self)
        app.queues.add(Foo(promise: promise))
        
        app.get("foo") { req in
            req.queue.dispatch(Foo.self, .init(foo: "bar"), id: JobIdentifier(string: "my-custom-id"))
                .map { _ in "done" }
        }
        
        try app.testable().test(.GET, "foo") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }
        
        XCTAssertEqual(app.queues.test.queue.count, 1)
        XCTAssertEqual(app.queues.test.jobs.count, 1)
        XCTAssertTrue(app.queues.test.jobs.keys.map(\.string).contains("my-custom-id"))
        
        try app.queues.queue.worker.run().wait()
        XCTAssertEqual(app.queues.test.queue.count, 0)
        XCTAssertEqual(app.queues.test.jobs.count, 0)
        
        try XCTAssertEqual(promise.futureResult.wait(), "bar")
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
