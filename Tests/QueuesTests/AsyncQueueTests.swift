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
    
    override func setUp() async throws {
        app = try await Application.make(.testing)
    }
    
    override func tearDown() async throws {
        try await app.asyncShutdown()
    }
    
    func testAsyncJob() async throws {
        app.queues.use(.test)
        
        let promise = app.eventLoopGroup.any().makePromise(of: Void.self)
        app.queues.add(MyAsyncJob(promise: promise))
        
        app.get("foo") { req in
            try await req.queue.dispatch(MyAsyncJob.self, .init(foo: "bar"))
            return "done"
        }
        
        try await app.testable().test(.GET, "foo") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "done")
        }
        
        XCTAssertEqual(app.queues.test.queue.count, 1)
        XCTAssertEqual(app.queues.test.jobs.count, 1)
        let job = app.queues.test.first(MyAsyncJob.self)
        XCTAssert(app.queues.test.contains(MyAsyncJob.self))
        XCTAssertNotNil(job)
        XCTAssertEqual(job!.foo, "bar")
        
        try await app.queues.queue.worker.run().get()
        XCTAssertEqual(app.queues.test.queue.count, 0)
        XCTAssertEqual(app.queues.test.jobs.count, 0)
        
        await XCTAssertNoThrowAsync(try await promise.futureResult.get())
    }
}

struct MyAsyncJob: AsyncJob {
    let promise: EventLoopPromise<Void>
    
    struct Data: Codable {
        var foo: String
    }
    
    func dequeue(_ context: QueueContext, _ payload: Data) async throws {
        self.promise.succeed()
    }
}
