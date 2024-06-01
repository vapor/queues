import Atomics
import Queues
import XCTest
import XCTVapor
import XCTQueues
import NIOConcurrencyHelpers

func XCTAssertEqualAsync<T>(
    _ expression1: @autoclosure () async throws -> T,
    _ expression2: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line
) async where T: Equatable {
    do {
        let expr1 = try await expression1(), expr2 = try await expression2()
        return XCTAssertEqual(expr1, expr2, message(), file: file, line: line)
    } catch {
        return XCTAssertEqual(try { () -> Bool in throw error }(), false, message(), file: file, line: line)
    }
}

final class QueueTests: XCTestCase {
    var app: Application!
    
    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        self.app.queues.use(.test)
    }
    
    override func tearDown() async throws {
        try await self.app.asyncShutdown()
        self.app = nil
    }
    
    func testVaporIntegrationWithInProcessJob() async throws {
        let jobSignal = self.app.eventLoopGroup.any().makePromise(of: String.self)
        self.app.queues.add(Foo(promise: jobSignal))
        try self.app.queues.startInProcessJobs(on: .default)
    
        self.app.get("bar") { req in
            try await req.queue.dispatch(Foo.self, .init(foo: "Bar payload"))
            return "job bar dispatched"
        }
        
        try await self.app.testable().test(.GET, "bar") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "job bar dispatched")
        }

        await XCTAssertEqualAsync(try await jobSignal.futureResult.get(), "Bar payload")
    }
    
    func testVaporIntegration() async throws {
        let promise = self.app.eventLoopGroup.any().makePromise(of: String.self)
        self.app.queues.add(Foo(promise: promise))
        
        self.app.get("foo") { req in
            try await req.queue.dispatch(Foo.self, .init(foo: "bar"))
            return "done"
        }
        
        try await self.app.testable().test(.GET, "foo") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }
        
        XCTAssertEqual(self.app.queues.test.queue.count, 1)
        XCTAssertEqual(self.app.queues.test.jobs.count, 1)
        let job = self.app.queues.test.first(Foo.self)
        XCTAssert(self.app.queues.test.contains(Foo.self))
        XCTAssertNotNil(job)
        XCTAssertEqual(job!.foo, "bar")
        
        try await self.app.queues.queue.worker.run()
        XCTAssertEqual(self.app.queues.test.queue.count, 0)
        XCTAssertEqual(self.app.queues.test.jobs.count, 0)
        
        await XCTAssertEqualAsync(try await promise.futureResult.get(), "bar")
    }

    func testSettingCustomId() async throws {
        let promise = self.app.eventLoopGroup.any().makePromise(of: String.self)
        self.app.queues.add(Foo(promise: promise))
        
        self.app.get("foo") { req in
            try await req.queue.dispatch(Foo.self, .init(foo: "bar"), id: JobIdentifier(string: "my-custom-id"))
            return "done"
        }
        
        try await self.app.testable().test(.GET, "foo") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }
        
        XCTAssertEqual(self.app.queues.test.queue.count, 1)
        XCTAssertEqual(self.app.queues.test.jobs.count, 1)
        XCTAssert(self.app.queues.test.jobs.keys.map(\.string).contains("my-custom-id"))
        
        try await self.app.queues.queue.worker.run()
        XCTAssertEqual(self.app.queues.test.queue.count, 0)
        XCTAssertEqual(self.app.queues.test.jobs.count, 0)
        
        await XCTAssertEqualAsync(try await promise.futureResult.get(), "bar")
    }
    
    func testScheduleBuilderAPI() async throws {
        // yearly
        self.app.queues.schedule(Cleanup()).yearly().in(.may).on(23).at(.noon)

        // monthly
        self.app.queues.schedule(Cleanup()).monthly().on(15).at(.midnight)

        // weekly
        self.app.queues.schedule(Cleanup()).weekly().on(.monday).at("3:13am")

        // daily
        self.app.queues.schedule(Cleanup()).daily().at("5:23pm")

        // daily 2
        self.app.queues.schedule(Cleanup()).daily().at(5, 23, .pm)

        // daily 3
        self.app.queues.schedule(Cleanup()).daily().at(17, 23)

        // hourly
        self.app.queues.schedule(Cleanup()).hourly().at(30)
    }
    
    func testRepeatingScheduledJob() async throws {
        let scheduledJob = TestingScheduledJob()
        XCTAssertEqual(scheduledJob.count.load(ordering: .relaxed), 0)
        self.app.queues.schedule(scheduledJob).everySecond()
        try self.app.queues.startScheduledJobs()
        
        let promise = self.app.eventLoopGroup.any().makePromise(of: Void.self)
        self.app.eventLoopGroup.any().scheduleTask(in: .seconds(5)) {
            XCTAssert(scheduledJob.count.load(ordering: .relaxed) > 4)
            promise.succeed()
        }
        
        try await promise.futureResult.get()
    }

    func testFailingScheduledJob() async throws {
        self.app.queues.schedule(FailingScheduledJob()).everySecond()
        try self.app.queues.startScheduledJobs()
        
        let promise = self.app.eventLoopGroup.any().makePromise(of: Void.self)
        self.app.eventLoopGroup.any().scheduleTask(in: .seconds(1)) {
            promise.succeed()
        }
        try await promise.futureResult.get()
    }

    func testCustomWorkerCount() async throws {
        // Setup custom ELG with 4 threads
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)
        
        do {
            let count = self.app.eventLoopGroup.any().makePromise(of: Int.self)
            self.app.queues.use(custom: WorkerCountDriver(count: count))
            // Limit worker count to less than 4 threads
            self.app.queues.configuration.workerCount = 2

            try self.app.queues.startInProcessJobs(on: .default)
            await XCTAssertEqualAsync(try await count.futureResult.get(), 2)
        } catch {
            try? await eventLoopGroup.shutdownGracefully()
            throw error
        }
        try await eventLoopGroup.shutdownGracefully()
    }

    func testSuccessHooks() async throws {
        let promise = self.app.eventLoopGroup.any().makePromise(of: String.self)
        let successHook = SuccessHook()
        let errorHook = ErrorHook()
        let dispatchHook = DispatchHook()
        let dequeuedHook = DequeuedHook()
        self.app.queues.add(Foo(promise: promise))
        self.app.queues.add(successHook)
        self.app.queues.add(errorHook)
        self.app.queues.add(dispatchHook)
        self.app.queues.add(dequeuedHook)

        self.app.get("foo") { req in
            try await req.queue.dispatch(Foo.self, .init(foo: "bar"))
            return "done"
        }

        XCTAssertFalse(dispatchHook.successHit)
        try await self.app.testable().test(.GET, "foo") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
            XCTAssertTrue(dispatchHook.successHit)
        }

        XCTAssertFalse(successHook.successHit)
        XCTAssertEqual(errorHook.errorCount, 0)
        XCTAssertEqual(self.app.queues.test.queue.count, 1)
        XCTAssertEqual(self.app.queues.test.jobs.count, 1)
        let job = self.app.queues.test.first(Foo.self)
        XCTAssert(self.app.queues.test.contains(Foo.self))
        XCTAssertNotNil(job)
        XCTAssertEqual(job!.foo, "bar")
        XCTAssertFalse(dequeuedHook.successHit)

        try await self.app.queues.queue.worker.run()
        XCTAssertTrue(successHook.successHit)
        XCTAssertEqual(errorHook.errorCount, 0)
        XCTAssertEqual(self.app.queues.test.queue.count, 0)
        XCTAssertEqual(self.app.queues.test.jobs.count, 0)
        XCTAssertTrue(dequeuedHook.successHit)
        
        await XCTAssertEqualAsync(try await promise.futureResult.get(), "bar")
    }

    func testFailureHooks() async throws {
        self.app.queues.use(.test)
        self.app.queues.add(Bar())
        let successHook = SuccessHook()
        let errorHook = ErrorHook()
        self.app.queues.add(successHook)
        self.app.queues.add(errorHook)
        
        self.app.get("foo") { req in
            try await req.queue.dispatch(Bar.self, .init(foo: "bar"), maxRetryCount: 3)
            return "done"
        }

        try await self.app.testable().test(.GET, "foo") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }

        XCTAssertFalse(successHook.successHit)
        XCTAssertEqual(errorHook.errorCount, 0)
        XCTAssertEqual(self.app.queues.test.queue.count, 1)
        XCTAssertEqual(self.app.queues.test.jobs.count, 1)
        let job = self.app.queues.test.first(Bar.self)
        XCTAssert(self.app.queues.test.contains(Bar.self))
        XCTAssertNotNil(job)

        try await self.app.queues.queue.worker.run()
        try await self.app.queues.queue.worker.run()
        try await self.app.queues.queue.worker.run()
        try await self.app.queues.queue.worker.run()
        XCTAssertFalse(successHook.successHit)
        XCTAssertEqual(errorHook.errorCount, 1)
        XCTAssertEqual(self.app.queues.test.queue.count, 0)
        XCTAssertEqual(self.app.queues.test.jobs.count, 0)
    }

    func testFailureHooksWithDelay() async throws {
        self.app.queues.add(Baz())
        let successHook = SuccessHook()
        let errorHook = ErrorHook()
        self.app.queues.add(successHook)
        self.app.queues.add(errorHook)

        self.app.get("foo") { req in
            try await req.queue.dispatch(Baz.self, .init(foo: "baz"), maxRetryCount: 1)
            return "done"
        }

        try await self.app.testable().test(.GET, "foo") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }

        XCTAssertFalse(successHook.successHit)
        XCTAssertEqual(errorHook.errorCount, 0)
        XCTAssertEqual(self.app.queues.test.queue.count, 1)
        XCTAssertEqual(self.app.queues.test.jobs.count, 1)
        var job = self.app.queues.test.first(Baz.self)
        XCTAssert(self.app.queues.test.contains(Baz.self))
        XCTAssertNotNil(job)

        try await self.app.queues.queue.worker.run()
        XCTAssertFalse(successHook.successHit)
        XCTAssertEqual(errorHook.errorCount, 0)
        XCTAssertEqual(self.app.queues.test.queue.count, 1)
        XCTAssertEqual(self.app.queues.test.jobs.count, 1)
        job = self.app.queues.test.first(Baz.self)
        XCTAssert(self.app.queues.test.contains(Baz.self))
        XCTAssertNotNil(job)

        sleep(1)

        try await self.app.queues.queue.worker.run()
        XCTAssertFalse(successHook.successHit)
        XCTAssertEqual(errorHook.errorCount, 1)
        XCTAssertEqual(self.app.queues.test.queue.count, 0)
        XCTAssertEqual(self.app.queues.test.jobs.count, 0)
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

        func get(_ id: JobIdentifier) -> EventLoopFuture<JobData> { fatalError() }
        func set(_ id: JobIdentifier, to data: JobData) -> EventLoopFuture<Void> { fatalError() }
        func clear(_ id: JobIdentifier) -> EventLoopFuture<Void> { fatalError() }
        func pop() -> EventLoopFuture<JobIdentifier?> {
            self.driver.record(eventLoop: self.context.eventLoop)
            return self.context.eventLoop.makeSucceededFuture(nil)
        }
        func push(_ id: JobIdentifier) -> EventLoopFuture<Void> { fatalError() }
    }
}

struct Failure: Error {}
struct FailingScheduledJob: ScheduledJob {
    func run(context: QueueContext) -> EventLoopFuture<Void> { context.eventLoop.makeFailedFuture(Failure()) }
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
        context.eventLoop.makeFailedFuture(Abort(.badRequest))
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
        attempt
    }
}
