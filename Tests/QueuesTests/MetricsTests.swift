@testable import CoreMetrics
import Metrics
import MetricsTestKit
import NIOConcurrencyHelpers
import Queues
@testable import Vapor
import XCTQueues
import XCTVapor

final class MetricsTests: XCTestCase {
    var app: Application!
    var metrics: TestMetrics!

    override func setUp() async throws {
        self.metrics = TestMetrics()
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

        let timer = try XCTUnwrap(self.metrics.timers.first(where: { $0.label == "MyAsyncJob.duration.timer" }))
        let successDimension = try XCTUnwrap(timer.dimensions.first(where: { $0.0 == "success" }))
        let idDimension = try XCTUnwrap(timer.dimensions.first(where: { $0.0 == "jobName" }))
        XCTAssertEqual(successDimension.1, "true")
        XCTAssertEqual(idDimension.1, "MyAsyncJob")

        try XCTAssertNoThrow(promise.futureResult.wait())
    }

    func testSuccessfullyCompletedJobsCounter() async throws {
        let promise = self.app.eventLoopGroup.next().makePromise(of: Void.self)
        self.app.queues.add(MyAsyncJob(promise: promise))

        self.app.get("foo") { req async throws in
            try await req.queue.dispatch(MyAsyncJob.self, .init(foo: "bar"))
            return "done"
        }

        try await self.app.testable().test(.GET, "foo") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }

        try await self.app.queues.queue.worker.run()
        let counter = try XCTUnwrap(self.metrics.counters.first(where: { $0.label == "success.completed.jobs.counter" }))
        let queueNameDimension = try XCTUnwrap(counter.dimensions.first(where: { $0.0 == "queueName" }))
        XCTAssertEqual(queueNameDimension.1, self.app.queues.queue.queueName.string)
        XCTAssertEqual(counter.lastValue, 1)
    }

    func testErroringJobsCounter() async throws {
        let promise = self.app.eventLoopGroup.next().makePromise(of: Void.self)
        self.app.queues.add(FailingAsyncJob(promise: promise))

        self.app.get("foo") { req async throws in
            try await req.queue.dispatch(FailingAsyncJob.self, .init(foo: "bar"))
            return "done"
        }

        try await self.app.testable().test(.GET, "foo") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }

        try await self.app.queues.queue.worker.run()
        let counter = try XCTUnwrap(self.metrics.counters.first(where: { $0.label == "error.completed.jobs.counter" }))
        let queueNameDimension = try XCTUnwrap(counter.dimensions.first(where: { $0.0 == "queueName" }))
        XCTAssertEqual(queueNameDimension.1, self.app.queues.queue.queueName.string)
        XCTAssertEqual(counter.lastValue, 1)
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

        let counter = try XCTUnwrap(self.metrics.counters.first(where: { $0.label == "dispatched.jobs.counter" }))
        let queueNameDimension = try XCTUnwrap(counter.dimensions.first(where: { $0.0 == "queueName" }))
        let jobNameDimension = try XCTUnwrap(counter.dimensions.first(where: { $0.0 == "jobName" }))
        XCTAssertEqual(queueNameDimension.1, self.app.queues.queue.queueName.string)
        XCTAssertEqual(jobNameDimension.1, MyAsyncJob.name)
        XCTAssertEqual(counter.totalValue, 2)
    }

    func testInProgressJobsGauge() async throws {
        let promise = self.app.eventLoopGroup.next().makePromise(of: Void.self)
        self.app.queues.add(MyAsyncJob(promise: promise))

        self.app.get("foo") { req async throws in
            try await req.queue.dispatch(MyAsyncJob.self, .init(foo: "bar"))
            return "done"
        }

        try await self.app.testable().test(.GET, "foo") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }

        try await self.app.queues.queue.worker.run()

        let meter = try XCTUnwrap(self.metrics.meters.first(where: { $0.label == "jobs.in.progress.meter" }))
        let queueNameDimension = try XCTUnwrap(meter.dimensions.first(where: { $0.0 == "queueName" }))
        XCTAssertEqual(queueNameDimension.1, self.app.queues.queue.queueName.string)
        XCTAssertEqual(meter.values, [1, 0])
    }
}
