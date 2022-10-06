@testable import CoreMetrics
import Metrics
import NIOConcurrencyHelpers
import Queues
@testable import Vapor
import XCTQueues
import XCTVapor

final class MetricsTests: XCTestCase {
    var app: Application!
    var metrics: CapturingMetricsSystem!

    override func setUp() async throws {
        self.metrics = CapturingMetricsSystem()
        MetricsSystem.bootstrapInternal(self.metrics)

        self.app = try await Application.make(.testing)
        self.app.queues.use(.test)
    }

    override func tearDown() async throws {
        try await self.app.asyncShutdown()
    }

    func testJobDurationTimer() async throws {
        let promise = self.app.eventLoopGroup.next().makePromise(of: Void.self)
        self.app.queues.add(MyAsyncJob(promise: promise))

        self.app.get("foo") { req async throws in
            try await req.queue.dispatch(MyAsyncJob.self, .init(foo: "bar"), id: JobIdentifier(string: "some-id"))
            return "done"
        }

        try await self.app.testable().test(.GET, "foo") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }

        try await self.app.queues.queue.worker.run()

        let timer = try XCTUnwrap(self.metrics.timers["some-id.jobDurationTimer"] as? TestTimer)
        let successDimension = try XCTUnwrap(timer.dimensions.first(where: { $0.0 == "success" }))
        let idDimension = try XCTUnwrap(timer.dimensions.first(where: { $0.0 == "id" }))
        XCTAssertEqual(successDimension.1, "true")
        XCTAssertEqual(idDimension.1, "some-id")

        try XCTAssertNoThrow(promise.futureResult.wait())
    }

    func testSuccessfullyCompletedJobsCounter() async throws {
        let promise = self.app.eventLoopGroup.next().makePromise(of: Void.self)
        let successHook = SuccessHook()
        let errorHook = ErrorHook()

        self.app.queues.add(MyAsyncJob(promise: promise))
        self.app.queues.add(successHook)
        self.app.queues.add(errorHook)

        self.app.get("foo") { req async throws in
            try await req.queue.dispatch(MyAsyncJob.self, .init(foo: "bar"), id: JobIdentifier(string: "first"))
            return "done"
        }

        try await self.app.testable().test(.GET, "foo") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }

        try await self.app.queues.queue.worker.run()
        XCTAssertEqual(successHook.successHit, true)
        XCTAssertEqual(errorHook.errorCount, 0)
        XCTAssertEqual(self.app.queues.test.queue.count, 0)
        XCTAssertEqual(self.app.queues.test.jobs.count, 0)

        let counter = try XCTUnwrap(self.metrics.counters["success.completed.jobs.counter"] as? TestCounter)
        let queueNameDimension = try XCTUnwrap(counter.dimensions.first(where: { $0.0 == "queueName" }))
        XCTAssertEqual(queueNameDimension.1, self.app.queues.queue.queueName.string)
        try XCTAssertNoThrow(promise.futureResult.wait())
    }

    func testDispatchedJobsCounter() async throws {
        let promise = self.app.eventLoopGroup.next().makePromise(of: Void.self)
        self.app.queues.add(MyAsyncJob(promise: promise))

        self.app.get("foo") { req async throws in
            try await req.queue.dispatch(MyAsyncJob.self, .init(foo: "bar"), id: JobIdentifier(string: "first"))
            try await req.queue.dispatch(MyAsyncJob.self, .init(foo: "rab"), id: JobIdentifier(string: "second"))
            return "done"
        }

        try await self.app.testable().test(.GET, "foo") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }

        try await self.app.queues.queue.worker.run()

        let counter = try XCTUnwrap(self.metrics.counters["dispatched.jobs.counter"] as? TestCounter)
        let queueNameDimension = try XCTUnwrap(counter.dimensions.first(where: { $0.0 == "queueName" }))
        XCTAssertEqual(queueNameDimension.1, self.app.queues.queue.queueName.string)
        try XCTAssertNoThrow(promise.futureResult.wait())
    }
}
