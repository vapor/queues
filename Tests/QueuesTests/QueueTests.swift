import Atomics
import Queues
import XCTest
import XCTVapor
import XCTQueues
import NIOConcurrencyHelpers

final class QueueTests: XCTestCase {
    func testVaporIntegrationWithInProcessJob() throws {
        let app = Application(.testing)
        app.queues.use(.test)
        defer { app.shutdown() }
        
        let jobSignal = app.eventLoopGroup.any().makePromise(of: String.self)
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
        
        let promise = app.eventLoopGroup.any().makePromise(of: String.self)
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
        
        let promise = app.eventLoopGroup.any().makePromise(of: String.self)
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
        
        let scheduledJob = TestingScheduledJob()
        XCTAssertEqual(scheduledJob.count.load(ordering: .relaxed), 0)
        app.queues.schedule(scheduledJob).everySecond()
        try app.queues.startScheduledJobs()
        
        let promise = app.eventLoopGroup.any().makePromise(of: Void.self)
        app.eventLoopGroup.any().scheduleTask(in: .seconds(5)) { () -> Void in
            XCTAssert(scheduledJob.count.load(ordering: .relaxed) > 4)
            promise.succeed(())
        }
        
        try promise.futureResult.wait()
    }

    func testFailingScheduledJob() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        app.queues.schedule(FailingScheduledJob()).everySecond()
        try app.queues.startScheduledJobs()
        
        let promise = app.eventLoopGroup.any().makePromise(of: Void.self)
        app.eventLoopGroup.any().scheduleTask(in: .seconds(1)) { () -> Void in
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

        let count = app.eventLoopGroup.any().makePromise(of: Int.self)
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

        let promise = app.eventLoopGroup.any().makePromise(of: String.self)
        let successHook = SuccessHook()
        let errorHook = ErrorHook()
        let dispatchHook = DispatchHook()
        let dequeuedHook = DequeuedHook()
        app.queues.add(Foo(promise: promise))
        app.queues.add(successHook)
        app.queues.add(errorHook)
        app.queues.add(dispatchHook)
        app.queues.add(dequeuedHook)

        app.get("foo") { req in
            req.queue.dispatch(Foo.self, .init(foo: "bar"))
                .map { _ in "done" }
        }

        XCTAssertFalse(dispatchHook.successHit)
        try app.testable().test(.GET, "foo") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
            XCTAssertTrue(dispatchHook.successHit)
        }

        XCTAssertFalse(successHook.successHit)
        XCTAssertEqual(errorHook.errorCount, 0)
        XCTAssertEqual(app.queues.test.queue.count, 1)
        XCTAssertEqual(app.queues.test.jobs.count, 1)
        let job = app.queues.test.first(Foo.self)
        XCTAssert(app.queues.test.contains(Foo.self))
        XCTAssertNotNil(job)
        XCTAssertEqual(job!.foo, "bar")
        XCTAssertFalse(dequeuedHook.successHit)

        try app.queues.queue.worker.run().wait()
        XCTAssertTrue(successHook.successHit)
        XCTAssertEqual(errorHook.errorCount, 0)
        XCTAssertEqual(app.queues.test.queue.count, 0)
        XCTAssertEqual(app.queues.test.jobs.count, 0)
        XCTAssertTrue(dequeuedHook.successHit)
        
        try XCTAssertEqual(promise.futureResult.wait(), "bar")
    }

    func testFailureHooks() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        app.queues.use(.test)
        app.queues.add(Bar())
        let successHook = SuccessHook()
        let errorHook = ErrorHook()
        app.queues.add(successHook)
        app.queues.add(errorHook)
        
        app.get("foo") { req in
            req.queue.dispatch(Bar.self, .init(foo: "bar"), maxRetryCount: 3)
                .map { _ in "done" }
        }

        try app.testable().test(.GET, "foo") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }

        XCTAssertFalse(successHook.successHit)
        XCTAssertEqual(errorHook.errorCount, 0)
        XCTAssertEqual(app.queues.test.queue.count, 1)
        XCTAssertEqual(app.queues.test.jobs.count, 1)
        let job = app.queues.test.first(Bar.self)
        XCTAssert(app.queues.test.contains(Bar.self))
        XCTAssertNotNil(job)

        try app.queues.queue.worker.run().wait()
        XCTAssertFalse(successHook.successHit)
        XCTAssertEqual(errorHook.errorCount, 1)
        XCTAssertEqual(app.queues.test.queue.count, 0)
        XCTAssertEqual(app.queues.test.jobs.count, 0)
    }

    func testFailureHooksWithDelay() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        app.queues.use(.test)
        app.queues.add(Baz())
        let successHook = SuccessHook()
        let errorHook = ErrorHook()
        app.queues.add(successHook)
        app.queues.add(errorHook)

        app.get("foo") { req in
            req.queue.dispatch(Baz.self, .init(foo: "baz"), maxRetryCount: 1)
                    .map { _ in "done" }
        }

        try app.testable().test(.GET, "foo") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }

        XCTAssertFalse(successHook.successHit)
        XCTAssertEqual(errorHook.errorCount, 0)
        XCTAssertEqual(app.queues.test.queue.count, 1)
        XCTAssertEqual(app.queues.test.jobs.count, 1)
        var job = app.queues.test.first(Baz.self)
        XCTAssert(app.queues.test.contains(Baz.self))
        XCTAssertNotNil(job)

        try app.queues.queue.worker.run().wait()
        XCTAssertFalse(successHook.successHit)
        XCTAssertEqual(errorHook.errorCount, 0)
        XCTAssertEqual(app.queues.test.queue.count, 1)
        XCTAssertEqual(app.queues.test.jobs.count, 1)
        job = app.queues.test.first(Baz.self)
        XCTAssert(app.queues.test.contains(Baz.self))
        XCTAssertNotNil(job)

        sleep(1)

        try app.queues.queue.worker.run().wait()
        XCTAssertFalse(successHook.successHit)
        XCTAssertEqual(errorHook.errorCount, 1)
        XCTAssertEqual(app.queues.test.queue.count, 0)
        XCTAssertEqual(app.queues.test.jobs.count, 0)
    }
}

final class DispatchHook: JobEventDelegate, @unchecked Sendable {
    var successHit = false

    func dispatched(job: JobEventData, eventLoop: any EventLoop) -> EventLoopFuture<Void> {
        self.successHit = true
        return eventLoop.makeSucceededVoidFuture()
    }
}

final class SuccessHook: JobEventDelegate, @unchecked Sendable {
    var successHit = false

    func success(jobId: String, eventLoop: any EventLoop) -> EventLoopFuture<Void> {
        self.successHit = true
        return eventLoop.makeSucceededVoidFuture()
    }
}

final class ErrorHook: JobEventDelegate, @unchecked Sendable {
    var errorCount = 0

    func error(jobId: String, error: any Error, eventLoop: any EventLoop) -> EventLoopFuture<Void> {
        self.errorCount += 1
        return eventLoop.makeSucceededVoidFuture()
    }
}

final class DequeuedHook: JobEventDelegate, @unchecked Sendable {
    var successHit = false

    func didDequeue(jobId: String, eventLoop: any EventLoop) -> EventLoopFuture<Void> {
        self.successHit = true
        return eventLoop.makeSucceededVoidFuture()
    }
}

final class WorkerCountDriver: QueuesDriver, @unchecked Sendable {
    let count: EventLoopPromise<Int>
    let lock: NIOLock
    var recordedEventLoops: Set<ObjectIdentifier>

    init(count: EventLoopPromise<Int>) {
        self.count = count
        self.lock = .init()
        self.recordedEventLoops = []
    }

    func makeQueue(with context: QueueContext) -> any Queue {
        WorkerCountQueue(driver: self, context: context)
    }

    func record(eventLoop: any EventLoop) {
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
    var count = ManagedAtomic<Int>(0)
    
    func run(context: QueueContext) -> EventLoopFuture<Void> {
        self.count.wrappingIncrement(ordering: .relaxed)
        return context.eventLoop.makeSucceededVoidFuture()
    }
}


struct Foo: Job {
    let promise: EventLoopPromise<String>
    
    struct Data: Codable {
        var foo: String
    }
    
    func dequeue(_ context: QueueContext, _ data: Data) -> EventLoopFuture<Void> {
        self.promise.succeed(data.foo)
        return context.eventLoop.makeSucceededVoidFuture()
    }
    
    func error(_ context: QueueContext, _ error: any Error, _ data: Data) -> EventLoopFuture<Void> {
        self.promise.fail(error)
        return context.eventLoop.makeSucceededVoidFuture()
    }
}

struct Bar: Job {
    struct Data: Codable {
        var foo: String
    }

    func dequeue(_ context: QueueContext, _ data: Data) -> EventLoopFuture<Void> {
        return context.eventLoop.makeFailedFuture(Abort(.badRequest))
    }

    func error(_ context: QueueContext, _ error: any Error, _ data: Data) -> EventLoopFuture<Void> {
        context.eventLoop.makeSucceededVoidFuture()
    }
}

struct Baz: Job {
    struct Data: Codable {
        var foo: String
    }

    func dequeue(_ context: QueueContext, _ data: Data) -> EventLoopFuture<Void> {
        context.eventLoop.makeFailedFuture(Abort(.badRequest))
    }

    func error(_ context: QueueContext, _ error: any Error, _ data: Data) -> EventLoopFuture<Void> {
        context.eventLoop.makeSucceededVoidFuture()
    }

    func nextRetryIn(attempt: Int) -> Int {
        return attempt
    }
}

