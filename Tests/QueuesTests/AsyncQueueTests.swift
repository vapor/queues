import Queues
import Foundation
import Vapor
import XCTest
import XCTVapor
import XCTQueues
@testable import Vapor
import NIOCore
import NIOConcurrencyHelpers

final class AsyncQueueTests: XCTestCase {
    func testAsyncJob() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        app.queues.use(.test)
        
        let promise = app.eventLoopGroup.any().makePromise(of: Void.self)
        app.queues.add(MyAsyncJob(promise: promise))
        
        app.get("foo") { req in
            req.queue.dispatch(MyAsyncJob.self, .init(foo: "bar"))
                .map { _ in "done" }
        }
        
        try app.testable().test(.GET, "foo") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }
        
        XCTAssertEqual(app.queues.test.queue.count, 1)
        XCTAssertEqual(app.queues.test.jobs.count, 1)
        let job = app.queues.test.first(MyAsyncJob.self)
        XCTAssert(app.queues.test.contains(MyAsyncJob.self))
        XCTAssertNotNil(job)
        XCTAssertEqual(job!.foo, "bar")
        
        try app.queues.queue.worker.run().wait()
        XCTAssertEqual(app.queues.test.queue.count, 0)
        XCTAssertEqual(app.queues.test.jobs.count, 0)
        
        try XCTAssertNoThrow(promise.futureResult.wait())
    }
}

struct MyAsyncJob: AsyncJob {
    let promise: EventLoopPromise<Void>
    
    struct Data: Codable {
        var foo: String
    }
    
    func dequeue(_ context: QueueContext, _ payload: Data) async throws {
        promise.succeed(())
        return
    }
}
