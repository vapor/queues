#if compiler(>=5.5) && canImport(_Concurrency)
import Metrics
import Queues
import Vapor
import XCTVapor
import XCTQueues
@testable import CoreMetrics
@testable import Vapor
import NIOConcurrencyHelpers

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
final class MetricsTests: XCTestCase {
    func testJobDurationTimer() throws {
        let metrics = CapturingMetricsSystem()
        MetricsSystem.bootstrapInternal(metrics)
        
        let app = Application(.testing)
        defer { app.shutdown() }
        app.queues.use(.test)
        
        let promise = app.eventLoopGroup.next().makePromise(of: Void.self)
        app.queues.add(AsyncFoo(promise: promise))
        
        app.get("foo") { req async throws in
            try await req.queue.dispatch(AsyncFoo.self, .init(foo: "bar"), id: JobIdentifier(string: "some-id"))
            return "done"
        }
        
        try app.testable().test(.GET, "foo") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }
        
        try app.queues.queue.worker.run().wait()
        
        let timer = metrics.timers["some-id.jobDurationTimer"] as! TestTimer
        let successDimension = try XCTUnwrap(timer.dimensions.first(where: { $0.0 == "success" }))
        let idDimension = try XCTUnwrap(timer.dimensions.first(where: { $0.0 == "id" }))
        XCTAssertEqual(successDimension.1, "true")
        XCTAssertEqual(idDimension.1, "some-id")
        
        try XCTAssertNoThrow(promise.futureResult.wait())
    }
    
    func testSuccessfullyCompletedJobsCounter() throws {
        let metrics = CapturingMetricsSystem()
        MetricsSystem.bootstrapInternal(metrics)

        let app = Application(.testing)
        app.queues.use(.test)
        defer { app.shutdown() }

        let promise = app.eventLoopGroup.next().makePromise(of: Void.self)
        app.queues.add(AsyncFoo(promise: promise))
        app.queues.add(SuccessHook())
        app.queues.add(ErrorHook())
        app.queues.add(DispatchHook())
        app.queues.add(DequeuedHook())
        ErrorHook.errorCount = 0
        DequeuedHook.successHit = false
        
        app.get("foo") { req async throws in
            try await req.queue.dispatch(AsyncFoo.self, .init(foo: "bar"), id: JobIdentifier(string: "first"))
            try await req.queue.dispatch(AsyncFoo.self, .init(foo: "rab"), id: JobIdentifier(string: "second"))
            return "done"
        }
        
        XCTAssertEqual(DispatchHook.successHit, false)
        try app.testable().test(.GET, "foo") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
            XCTAssertEqual(DispatchHook.successHit, true)
        }
        
        XCTAssertEqual(SuccessHook.successHit, false)
        XCTAssertEqual(ErrorHook.errorCount, 0)
        XCTAssertEqual(app.queues.test.queue.count, 2)
        XCTAssertEqual(app.queues.test.jobs.count, 2)
        let firstJob = app.queues.test.first(AsyncFoo.self)
        XCTAssert(app.queues.test.contains(AsyncFoo.self))
        XCTAssertNotNil(firstJob)
        XCTAssertEqual(firstJob!.foo, "bar")
        XCTAssertEqual(DequeuedHook.successHit, false)
        
        try app.queues.queue.worker.run().wait()
        XCTAssertEqual(SuccessHook.successHit, true)
        XCTAssertEqual(ErrorHook.errorCount, 0)
        XCTAssertEqual(app.queues.test.queue.count, 1)
        XCTAssertEqual(app.queues.test.jobs.count, 1)
        XCTAssertEqual(DequeuedHook.successHit, true)
        
        try app.queues.queue.worker.run().wait()
        XCTAssertEqual(SuccessHook.successHit, true)
        XCTAssertEqual(ErrorHook.errorCount, 0)
        XCTAssertEqual(app.queues.test.queue.count, 0)
        XCTAssertEqual(app.queues.test.jobs.count, 0)
        XCTAssertEqual(DequeuedHook.successHit, true)
        
        let counter = metrics.counters["success.completed.jobs.counter"] as! TestCounter
        let queueNameDimension = try XCTUnwrap(counter.dimensions.first(where: { $0.0 == "queueName" }))
        XCTAssertEqual(queueNameDimension.1, app.queues.queue.queueName.string)
        try XCTAssertNoThrow(promise.futureResult.wait())
    }
    
    func testDispatchedJobsCounter() throws {
        let metrics = CapturingMetricsSystem()
        MetricsSystem.bootstrapInternal(metrics)

        let app = Application(.testing)
        app.queues.use(.test)
        defer { app.shutdown() }

        let promise = app.eventLoopGroup.next().makePromise(of: Void.self)
        app.queues.add(AsyncFoo(promise: promise))
        
        app.get("foo") { req async throws in
            try await req.queue.dispatch(AsyncFoo.self, .init(foo: "bar"), id: JobIdentifier(string: "first"))
            try await req.queue.dispatch(AsyncFoo.self, .init(foo: "rab"), id: JobIdentifier(string: "second"))
            return "done"
        }
        
        try app.testable().test(.GET, "foo") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }
        
        try app.queues.queue.worker.run().wait()
        
        let counter = metrics.counters["dispatched.jobs.counter"] as! TestCounter
        let queueNameDimension = try XCTUnwrap(counter.dimensions.first(where: { $0.0 == "queueName" }))
        XCTAssertEqual(queueNameDimension.1, app.queues.queue.queueName.string)
        try XCTAssertNoThrow(promise.futureResult.wait())
    }
}
#endif
