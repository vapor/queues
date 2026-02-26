import Atomics
import NIOConcurrencyHelpers
import Queues
import XCTest
import XCTQueues
import XCTVapor

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

func XCTAssertTrueAsync(
    _ predicate: @autoclosure () async throws -> Bool,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line
) async {
    do {
        let result = try await predicate()
        XCTAssertTrue(result, message(), file: file, line: line)
    } catch {
        return XCTAssertTrue(try { throw error }(), message(), file: file, line: line)
    }
}

func XCTAssertFalseAsync(
    _ predicate: @autoclosure () async throws -> Bool,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line
) async {
    do {
        let result = try await predicate()
        XCTAssertFalse(result, message(), file: file, line: line)
    } catch {
        return XCTAssertFalse(try { throw error }(), message(), file: file, line: line)
    }
}

final class QueueTests: XCTestCase {
    var app: Application!

    override class func setUp() {
        XCTAssert(isLoggingConfigured)
    }

    override func setUp() async throws {
        self.app = try await Application.make(.testing)
        self.app.queues.use(.test)
    }

    override func tearDown() async throws {
        try await self.app.asyncShutdown()
        self.app = nil
    }

    func testVaporIntegrationWithInProcessJob() async throws {
        let jobSignal1 = self.app.eventLoopGroup.any().makePromise(of: String.self)
        self.app.queues.add(Foo1(promise: jobSignal1))
        let jobSignal2 = self.app.eventLoopGroup.any().makePromise(of: String.self)
        self.app.queues.add(Foo2(promise: jobSignal2))
        try self.app.queues.startInProcessJobs(on: .default)

        self.app.get("bar1") { req in
            try await req.queue.dispatch(Foo1.self, .init(foo: "Bar payload")).get()
            return "job bar dispatched"
        }

        self.app.get("bar2") { req in
            try await req.queue.dispatch(Foo2.self, .init(foo: "Bar payload"))
            return "job bar dispatched"
        }

        try await self.app.testable().test(.GET, "bar1") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "job bar dispatched")
        }.test(.GET, "bar2") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "job bar dispatched")
        }

        await XCTAssertEqualAsync(try await jobSignal1.futureResult.get(), "Bar payload")
        await XCTAssertEqualAsync(try await jobSignal2.futureResult.get(), "Bar payload")
    }

    func testVaporIntegration() async throws {
        let promise = self.app.eventLoopGroup.any().makePromise(of: String.self)
        self.app.queues.add(Foo1(promise: promise))

        self.app.get("foo") { req in
            try await req.queue.dispatch(Foo1.self, .init(foo: "bar"))
            return "done"
        }

        try await self.app.testable().test(.GET, "foo") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }

        XCTAssertEqual(self.app.queues.test.queue.count, 1)
        XCTAssertEqual(self.app.queues.test.jobs.count, 1)
        let job = self.app.queues.test.first(Foo1.self)
        XCTAssert(self.app.queues.test.contains(Foo1.self))
        XCTAssertNotNil(job)
        XCTAssertEqual(job!.foo, "bar")

        try await self.app.queues.queue.worker.run()
        XCTAssertEqual(self.app.queues.test.queue.count, 0)
        XCTAssertEqual(self.app.queues.test.jobs.count, 0)

        await XCTAssertEqualAsync(try await promise.futureResult.get(), "bar")
    }

    func testRunUntilEmpty() async throws {
        let promise1 = self.app.eventLoopGroup.any().makePromise(of: String.self)
        self.app.queues.add(Foo1(promise: promise1))
        let promise2 = self.app.eventLoopGroup.any().makePromise(of: String.self)
        self.app.queues.add(Foo2(promise: promise2))

        self.app.get("foo") { req in
            try await req.queue.dispatch(Foo1.self, .init(foo: "bar"))
            try await req.queue.dispatch(Foo1.self, .init(foo: "quux"))
            try await req.queue.dispatch(Foo2.self, .init(foo: "baz"))
            return "done"
        }

        try await self.app.testable().test(.GET, "foo") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }

        XCTAssertEqual(self.app.queues.test.queue.count, 3)
        XCTAssertEqual(self.app.queues.test.jobs.count, 3)
        try await self.app.queues.queue.worker.run()
        XCTAssertEqual(self.app.queues.test.queue.count, 0)
        XCTAssertEqual(self.app.queues.test.jobs.count, 0)

        await XCTAssertEqualAsync(try await promise1.futureResult.get(), "quux")
        await XCTAssertEqualAsync(try await promise2.futureResult.get(), "baz")
    }

    func testSettingCustomId() async throws {
        let promise = self.app.eventLoopGroup.any().makePromise(of: String.self)
        self.app.queues.add(Foo1(promise: promise))

        self.app.get("foo") { req in
            try await req.queue.dispatch(Foo1.self, .init(foo: "bar"), id: JobIdentifier(string: "my-custom-id"))
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

    func testAsyncRepeatingScheduledJob() async throws {
        let scheduledJob = AsyncTestingScheduledJob()
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

    func testAsyncFailingScheduledJob() async throws {
        self.app.queues.schedule(AsyncFailingScheduledJob()).everySecond()
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
        self.app.queues.add(Foo1(promise: promise))
        self.app.queues.add(successHook)
        self.app.queues.add(errorHook)
        self.app.queues.add(dispatchHook)
        self.app.queues.add(dequeuedHook)

        self.app.get("foo") { req in
            try await req.queue.dispatch(Foo1.self, .init(foo: "bar"))
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
        let job = self.app.queues.test.first(Foo1.self)
        XCTAssert(self.app.queues.test.contains(Foo1.self))
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

    func testAsyncSuccessHooks() async throws {
        let promise = self.app.eventLoopGroup.any().makePromise(of: String.self)
        let successHook = AsyncSuccessHook()
        let errorHook = AsyncErrorHook()
        let dispatchHook = AsyncDispatchHook()
        let dequeuedHook = AsyncDequeuedHook()
        self.app.queues.add(Foo1(promise: promise))
        self.app.queues.add(successHook)
        self.app.queues.add(errorHook)
        self.app.queues.add(dispatchHook)
        self.app.queues.add(dequeuedHook)

        self.app.get("foo") { req in
            try await req.queue.dispatch(Foo1.self, .init(foo: "bar"))
            return "done"
        }

        await XCTAssertFalseAsync(await dispatchHook.successHit)
        try await self.app.testable().test(.GET, "foo") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
            await XCTAssertTrueAsync(await dispatchHook.successHit)
        }

        await XCTAssertFalseAsync(await successHook.successHit)
        await XCTAssertEqualAsync(await errorHook.errorCount, 0)
        XCTAssertEqual(self.app.queues.test.queue.count, 1)
        XCTAssertEqual(self.app.queues.test.jobs.count, 1)
        let job = self.app.queues.test.first(Foo1.self)
        XCTAssert(self.app.queues.test.contains(Foo1.self))
        XCTAssertNotNil(job)
        XCTAssertEqual(job!.foo, "bar")
        await XCTAssertFalseAsync(await dequeuedHook.successHit)

        try await self.app.queues.queue.worker.run()
        await XCTAssertTrueAsync(await successHook.successHit)
        await XCTAssertEqualAsync(await errorHook.errorCount, 0)
        XCTAssertEqual(self.app.queues.test.queue.count, 0)
        XCTAssertEqual(self.app.queues.test.jobs.count, 0)
        await XCTAssertTrueAsync(await dequeuedHook.successHit)

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

    func testAsyncFailureHooks() async throws {
        self.app.queues.use(.test)
        self.app.queues.add(Bar())
        let successHook = AsyncSuccessHook()
        let errorHook = AsyncErrorHook()
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

        await XCTAssertFalseAsync(await successHook.successHit)
        await XCTAssertEqualAsync(await errorHook.errorCount, 0)
        XCTAssertEqual(self.app.queues.test.queue.count, 1)
        XCTAssertEqual(self.app.queues.test.jobs.count, 1)
        let job = self.app.queues.test.first(Bar.self)
        XCTAssert(self.app.queues.test.contains(Bar.self))
        XCTAssertNotNil(job)

        try await self.app.queues.queue.worker.run()
        try await self.app.queues.queue.worker.run()
        try await self.app.queues.queue.worker.run()
        try await self.app.queues.queue.worker.run()
        await XCTAssertFalseAsync(await successHook.successHit)
        await XCTAssertEqualAsync(await errorHook.errorCount, 1)
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

        try await Task.sleep(nanoseconds: 1_000_000_000)

        try await self.app.queues.queue.worker.run()
        XCTAssertFalse(successHook.successHit)
        XCTAssertEqual(errorHook.errorCount, 1)
        XCTAssertEqual(self.app.queues.test.queue.count, 0)
        XCTAssertEqual(self.app.queues.test.jobs.count, 0)
    }

    func testAsyncFailureHooksWithDelay() async throws {
        self.app.queues.add(Baz())
        let successHook = AsyncSuccessHook()
        let errorHook = AsyncErrorHook()
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

        await XCTAssertFalseAsync(await successHook.successHit)
        await XCTAssertEqualAsync(await errorHook.errorCount, 0)
        XCTAssertEqual(self.app.queues.test.queue.count, 1)
        XCTAssertEqual(self.app.queues.test.jobs.count, 1)
        var job = self.app.queues.test.first(Baz.self)
        XCTAssert(self.app.queues.test.contains(Baz.self))
        XCTAssertNotNil(job)

        try await self.app.queues.queue.worker.run()
        await XCTAssertFalseAsync(await successHook.successHit)
        await XCTAssertEqualAsync(await errorHook.errorCount, 0)
        XCTAssertEqual(self.app.queues.test.queue.count, 1)
        XCTAssertEqual(self.app.queues.test.jobs.count, 1)
        job = self.app.queues.test.first(Baz.self)
        XCTAssert(self.app.queues.test.contains(Baz.self))
        XCTAssertNotNil(job)

        try await Task.sleep(nanoseconds: 1_000_000_000)

        try await self.app.queues.queue.worker.run()
        await XCTAssertFalseAsync(await successHook.successHit)
        await XCTAssertEqualAsync(await errorHook.errorCount, 1)
        XCTAssertEqual(self.app.queues.test.queue.count, 0)
        XCTAssertEqual(self.app.queues.test.jobs.count, 0)
    }

    func testStuffThatIsntActuallyUsedAnywhere() {
        XCTAssertEqual(self.app.queues.queue(.default).key, "vapor_queues[default]")
        XCTAssertNotNil(QueuesEventLoopPreference.indifferent.delegate(for: self.app.eventLoopGroup))
        XCTAssertNotNil(QueuesEventLoopPreference.delegate(on: self.app.eventLoopGroup.any()).delegate(for: self.app.eventLoopGroup))
    }
}

final class DispatchHook: JobEventDelegate, @unchecked Sendable {
    var successHit = false

    func dispatched(job _: JobEventData, eventLoop: any EventLoop) -> EventLoopFuture<Void> {
        self.successHit = true
        return eventLoop.makeSucceededVoidFuture()
    }
}

final class SuccessHook: JobEventDelegate, @unchecked Sendable {
    var successHit = false

    func success(jobId _: String, eventLoop: any EventLoop) -> EventLoopFuture<Void> {
        self.successHit = true
        return eventLoop.makeSucceededVoidFuture()
    }
}

final class ErrorHook: JobEventDelegate, @unchecked Sendable {
    var errorCount = 0

    func error(jobId _: String, error _: any Error, eventLoop: any EventLoop) -> EventLoopFuture<Void> {
        self.errorCount += 1
        return eventLoop.makeSucceededVoidFuture()
    }
}

final class DequeuedHook: JobEventDelegate, @unchecked Sendable {
    var successHit = false

    func didDequeue(jobId _: String, eventLoop: any EventLoop) -> EventLoopFuture<Void> {
        self.successHit = true
        return eventLoop.makeSucceededVoidFuture()
    }
}

actor AsyncDispatchHook: AsyncJobEventDelegate {
    var successHit = false
    func dispatched(job _: JobEventData) async throws { self.successHit = true }
}

actor AsyncSuccessHook: AsyncJobEventDelegate {
    var successHit = false
    func success(jobId _: String) async throws { self.successHit = true }
}

actor AsyncErrorHook: AsyncJobEventDelegate {
    var errorCount = 0
    func error(jobId _: String, error _: any Error) async throws { self.errorCount += 1 }
}

actor AsyncDequeuedHook: AsyncJobEventDelegate {
    var successHit = false
    func didDequeue(jobId _: String) async throws { self.successHit = true }
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

        func get(_: JobIdentifier) -> EventLoopFuture<JobData> { fatalError() }
        func set(_: JobIdentifier, to _: JobData) -> EventLoopFuture<Void> { fatalError() }
        func clear(_: JobIdentifier) -> EventLoopFuture<Void> { fatalError() }
        func pop() -> EventLoopFuture<JobIdentifier?> {
            self.driver.record(eventLoop: self.context.eventLoop)
            return self.context.eventLoop.makeSucceededFuture(nil)
        }

        func push(_: JobIdentifier) -> EventLoopFuture<Void> { fatalError() }
    }
}

struct FailingScheduledJob: ScheduledJob {
    func run(context: QueueContext) -> EventLoopFuture<Void> { context.eventLoop.makeFailedFuture(Failure()) }
}

struct AsyncFailingScheduledJob: AsyncScheduledJob {
    func run(context _: QueueContext) async throws { throw Failure() }
}

struct TestingScheduledJob: ScheduledJob {
    var count = ManagedAtomic<Int>(0)

    func run(context: QueueContext) -> EventLoopFuture<Void> {
        self.count.wrappingIncrement(ordering: .relaxed)
        return context.eventLoop.makeSucceededVoidFuture()
    }
}

struct AsyncTestingScheduledJob: AsyncScheduledJob {
    var count = ManagedAtomic<Int>(0)
    func run(context _: QueueContext) async throws { self.count.wrappingIncrement(ordering: .relaxed) }
}

struct Foo1: Job {
    let promise: EventLoopPromise<String>

    struct Data: Codable {
        var foo: String
    }

    func dequeue(_ context: QueueContext, _ data: Data) -> EventLoopFuture<Void> {
        self.promise.succeed(data.foo)
        return context.eventLoop.makeSucceededVoidFuture()
    }

    func error(_ context: QueueContext, _ error: any Error, _: Data) -> EventLoopFuture<Void> {
        self.promise.fail(error)
        return context.eventLoop.makeSucceededVoidFuture()
    }
}

struct Foo2: Job {
    let promise: EventLoopPromise<String>

    struct Data: Codable {
        var foo: String
    }

    func dequeue(_ context: QueueContext, _ data: Data) -> EventLoopFuture<Void> {
        self.promise.succeed(data.foo)
        return context.eventLoop.makeSucceededVoidFuture()
    }

    func error(_ context: QueueContext, _ error: any Error, _: Data) -> EventLoopFuture<Void> {
        self.promise.fail(error)
        return context.eventLoop.makeSucceededVoidFuture()
    }
}

struct Bar: Job {
    struct Data: Codable {
        var foo: String
    }

    func dequeue(_ context: QueueContext, _: Data) -> EventLoopFuture<Void> {
        context.eventLoop.makeFailedFuture(Abort(.badRequest))
    }

    func error(_ context: QueueContext, _: any Error, _: Data) -> EventLoopFuture<Void> {
        context.eventLoop.makeSucceededVoidFuture()
    }
}

struct Baz: Job {
    struct Data: Codable {
        var foo: String
    }

    func dequeue(_ context: QueueContext, _: Data) -> EventLoopFuture<Void> {
        context.eventLoop.makeFailedFuture(Abort(.badRequest))
    }

    func error(_ context: QueueContext, _: any Error, _: Data) -> EventLoopFuture<Void> {
        context.eventLoop.makeSucceededVoidFuture()
    }

    func nextRetryIn(attempt: Int) -> Int {
        attempt
    }
}
