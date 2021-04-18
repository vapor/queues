import Queues
import Vapor
import XCTVapor
import XCTQueues
@testable import Vapor
import NIOConcurrencyHelpers

final class QueueTests: XCTestCase {
    func testVaporIntegrationWithInProcessJob() throws {
        let app = Application(.testing)
        app.queues.use(.test)
        defer { app.shutdown() }

        let jobSignal = app.eventLoopGroup.next().makePromise(of: String.self)
        app.queues.add(Foo(promise: jobSignal))
        try app.queues.startInProcessJobs(on: .default)

        app.get("bar") { req in
            req.queue.dispatch(Foo.self, .init(foo: "Bar payload"))
                .map { _ in "job bar dispatched" }
        }

        try app.testable().test(.GET, "bar") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "job bar dispatched")
        }

        try XCTAssertEqual(jobSignal.futureResult.wait(), "Bar payload")
    }

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

        // MARK: `.every` functions

        // hourly 1
        app.queues.schedule(Cleanup())
            .hourly()
            .every(.seconds(1))

        // hourly 2
        app.queues.schedule(Cleanup())
            .hourly()
            .every(.seconds(2500))

        // hourly 3
        app.queues.schedule(Cleanup())
            .hourly()
            .every(.hours(1))

        // minutely
        app.queues.schedule(Cleanup())
            .minutely()
            .every(.seconds(10))

        // every second
        app.queues.schedule(Cleanup())
            .everySecond()

        // secondly
        app.queues.schedule(Cleanup())
            .every(.milliseconds(10), in: .seconds(1))

        // (very-little-time)-ly
        app.queues.schedule(Cleanup())
            .every(.nanoseconds(1), in: .nanoseconds(30))

    }

    func testRepeatingScheduledJob() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        XCTAssertEqual(TestingScheduledJob.count.load(), 0)
        app.queues.schedule(TestingScheduledJob()).everySecond()
        try app.queues.startScheduledJobs()

        let promise = app.eventLoopGroup.next().makePromise(of: Void.self)
        app.eventLoopGroup.next().scheduleTask(in: .seconds(5)) { () -> Void in
            XCTAssertEqual(TestingScheduledJob.count.load(), 4)
            promise.succeed(())
        }

        try promise.futureResult.wait()
    }

    func testFailingScheduledJob() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.queues.schedule(FailingScheduledJob()).everySecond()
        try app.queues.startScheduledJobs()

        let promise = app.eventLoopGroup.next().makePromise(of: Void.self)
        app.eventLoopGroup.next().scheduleTask(in: .seconds(1)) { () -> Void in
            promise.succeed(())
        }
        try promise.futureResult.wait()
    }

    func testCustomWorkerCount() throws {
        // Setup custom ELG with 4 threads
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)
        defer { try! eventLoopGroup.syncShutdownGracefully() }

        let app = Application(.testing, .shared(eventLoopGroup))
        defer { app.shutdown() }

        let count = app.eventLoopGroup.next().makePromise(of: Int.self)
        app.queues.use(custom: WorkerCountDriver(count: count))
        // Limit worker count to less than 4 threads
        app.queues.configuration.workerCount = 2

        try app.queues.startInProcessJobs(on: .default)
        try XCTAssertEqual(count.futureResult.wait(), 2)
    }

    func testSuccessHooks() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        app.queues.use(.test)

        let promise = app.eventLoopGroup.next().makePromise(of: String.self)
        app.queues.add(Foo(promise: promise))
        app.queues.add(SuccessHook())
        app.queues.add(ErrorHook())
        app.queues.add(DispatchHook())
        app.queues.add(DequeuedHook())
        ErrorHook.errorCount = 0
        DequeuedHook.successHit = false

        app.get("foo") { req in
            req.queue.dispatch(Foo.self, .init(foo: "bar"))
                .map { _ in "done" }
        }

        XCTAssertEqual(DispatchHook.successHit, false)
        try app.testable().test(.GET, "foo") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
            XCTAssertEqual(DispatchHook.successHit, true)
        }

        XCTAssertEqual(SuccessHook.successHit, false)
        XCTAssertEqual(ErrorHook.errorCount, 0)
        XCTAssertEqual(app.queues.test.queue.count, 1)
        XCTAssertEqual(app.queues.test.jobs.count, 1)
        let job = app.queues.test.first(Foo.self)
        XCTAssert(app.queues.test.contains(Foo.self))
        XCTAssertNotNil(job)
        XCTAssertEqual(job!.foo, "bar")
        XCTAssertEqual(DequeuedHook.successHit, false)

        try app.queues.queue.worker.run().wait()
        XCTAssertEqual(SuccessHook.successHit, true)
        XCTAssertEqual(ErrorHook.errorCount, 0)
        XCTAssertEqual(app.queues.test.queue.count, 0)
        XCTAssertEqual(app.queues.test.jobs.count, 0)
        XCTAssertEqual(DequeuedHook.successHit, true)

        try XCTAssertEqual(promise.futureResult.wait(), "bar")
    }

    func testFailureHooks() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        app.queues.use(.test)
        app.queues.add(Bar())
        app.queues.add(SuccessHook())
        app.queues.add(ErrorHook())

        app.get("foo") { req in
            req.queue.dispatch(Bar.self, .init(foo: "bar"), maxRetryCount: 3)
                .map { _ in "done" }
        }

        try app.testable().test(.GET, "foo") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }

        XCTAssertEqual(SuccessHook.successHit, false)
        XCTAssertEqual(ErrorHook.errorCount, 0)
        XCTAssertEqual(app.queues.test.queue.count, 1)
        XCTAssertEqual(app.queues.test.jobs.count, 1)
        let job = app.queues.test.first(Bar.self)
        XCTAssert(app.queues.test.contains(Bar.self))
        XCTAssertNotNil(job)

        try app.queues.queue.worker.run().wait()
        XCTAssertEqual(SuccessHook.successHit, false)
        XCTAssertEqual(ErrorHook.errorCount, 1)
        XCTAssertEqual(app.queues.test.queue.count, 0)
        XCTAssertEqual(app.queues.test.jobs.count, 0)
    }
}

class DispatchHook: JobEventDelegate {
    static var successHit = false

    func dispatched(job: JobEventData, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        Self.successHit = true
        return eventLoop.future()
    }
}

class SuccessHook: JobEventDelegate {
    static var successHit = false

    func success(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        Self.successHit = true
        return eventLoop.future()
    }
}

class ErrorHook: JobEventDelegate {
    static var errorCount = 0

    func error(jobId: String, error: Error, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        Self.errorCount += 1
        return eventLoop.future()
    }
}

class DequeuedHook: JobEventDelegate {
    static var successHit = false

    func didDequeue(jobId: String, eventLoop: EventLoop) -> EventLoopFuture<Void> {
        Self.successHit = true
        return eventLoop.future()
    }
}

final class WorkerCountDriver: QueuesDriver {
    let count: EventLoopPromise<Int>
    let lock: Lock
    var recordedEventLoops: Set<ObjectIdentifier>

    init(count: EventLoopPromise<Int>) {
        self.count = count
        self.lock = .init()
        self.recordedEventLoops = []
    }

    func makeQueue(with context: QueueContext) -> Queue {
        WorkerCountQueue(driver: self, context: context)
    }

    func record(eventLoop: EventLoop) {
        self.lock.lock()
        defer { self.lock.unlock() }
        let previousCount = self.recordedEventLoops.count
        self.recordedEventLoops.insert(.init(eventLoop))
        if self.recordedEventLoops.count == previousCount {
            // we've detected all unique event loops now
            self.count.succeed(previousCount)
        }
    }

    func shutdown() {
        // nothing
    }

    private struct WorkerCountQueue: Queue {
        let driver: WorkerCountDriver
        var context: QueueContext

        func get(_ id: JobIdentifier) -> EventLoopFuture<JobData> {
            fatalError()
        }

        func set(_ id: JobIdentifier, to data: JobData) -> EventLoopFuture<Void> {
            fatalError()
        }

        func clear(_ id: JobIdentifier) -> EventLoopFuture<Void> {
            fatalError()
        }

        func pop() -> EventLoopFuture<JobIdentifier?> {
            self.driver.record(eventLoop: self.context.eventLoop)
            return self.context.eventLoop.makeSucceededFuture(nil)
        }

        func push(_ id: JobIdentifier) -> EventLoopFuture<Void> {
            fatalError()
        }
    }
}

struct Failure: Error { }
struct FailingScheduledJob: ScheduledJob {
    func run(context: QueueContext) -> EventLoopFuture<Void> {
        context.eventLoop.makeFailedFuture(Failure())
    }
}

struct TestingScheduledJob: ScheduledJob {
    static var count = NIOAtomic<Int>.makeAtomic(value: 0)

    func run(context: QueueContext) -> EventLoopFuture<Void> {
        TestingScheduledJob.count.add(1)
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

struct Bar: Job {
    struct Data: Codable {
        var foo: String
    }

    func dequeue(_ context: QueueContext, _ data: Data) -> EventLoopFuture<Void> {
        return context.eventLoop.makeFailedFuture(Abort(.badRequest))
    }

    func error(_ context: QueueContext, _ error: Error, _ data: Data) -> EventLoopFuture<Void> {
        return context.eventLoop.makeSucceededFuture(())
    }
}
