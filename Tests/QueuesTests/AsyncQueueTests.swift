import Queues
import XCTest
import XCTVapor

func XCTAssertNoThrowAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line
) async {
    do {
        _ = try await expression()
    } catch {
        XCTAssertNoThrow(try { throw error }(), message(), file: file, line: line)
    }
}

final class AsyncQueueTests: XCTestCase {
    var app: Application!

    override class func setUp() {
        XCTAssert(isLoggingConfigured)
    }

    override func setUp() async throws {
        self.app = try await Application.make(.testing)
    }

    override func tearDown() async throws {
        try await self.app.asyncShutdown()
    }

    func testAsyncJobWithSyncQueue() async throws {
        self.app.queues.use(.test)

        let promise = self.app.eventLoopGroup.any().makePromise(of: Void.self)
        self.app.queues.add(MyAsyncJob(promise: promise))

        self.app.get("foo") { req in
            try await req.queue.dispatch(MyAsyncJob.self, .init(foo: "bar"))
            try await req.queue.dispatch(MyAsyncJob.self, .init(foo: "baz"))
            try await req.queue.dispatch(MyAsyncJob.self, .init(foo: "quux"))
            return "done"
        }

        try await self.app.testable().test(.GET, "foo") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }

        XCTAssertEqual(self.app.queues.test.queue.count, 3)
        XCTAssertEqual(self.app.queues.test.jobs.count, 3)
        let job = self.app.queues.test.first(MyAsyncJob.self)
        XCTAssert(self.app.queues.test.contains(MyAsyncJob.self))
        XCTAssertNotNil(job)
        XCTAssertEqual(job!.foo, "bar")

        try await self.app.queues.queue.worker.run().get()
        XCTAssertEqual(self.app.queues.test.queue.count, 0)
        XCTAssertEqual(self.app.queues.test.jobs.count, 0)

        await XCTAssertNoThrowAsync(try await promise.futureResult.get())
    }

    func testAsyncJobWithAsyncQueue() async throws {
        self.app.queues.use(.asyncTest)

        let promise = self.app.eventLoopGroup.any().makePromise(of: Void.self)
        self.app.queues.add(MyAsyncJob(promise: promise))

        self.app.get("foo") { req in
            try await req.queue.dispatch(MyAsyncJob.self, .init(foo: "bar"))
            try await req.queue.dispatch(MyAsyncJob.self, .init(foo: "baz"))
            try await req.queue.dispatch(MyAsyncJob.self, .init(foo: "quux"))
            return "done"
        }

        try await self.app.testable().test(.GET, "foo") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }

        XCTAssertEqual(self.app.queues.asyncTest.queue.count, 3)
        XCTAssertEqual(self.app.queues.asyncTest.jobs.count, 3)
        let job = self.app.queues.asyncTest.first(MyAsyncJob.self)
        XCTAssert(self.app.queues.asyncTest.contains(MyAsyncJob.self))
        XCTAssertNotNil(job)
        XCTAssertEqual(job!.foo, "bar")

        try await self.app.queues.queue.worker.run().get()
        XCTAssertEqual(self.app.queues.asyncTest.queue.count, 0)
        XCTAssertEqual(self.app.queues.asyncTest.jobs.count, 0)

        await XCTAssertNoThrowAsync(try await promise.futureResult.get())
    }
}
