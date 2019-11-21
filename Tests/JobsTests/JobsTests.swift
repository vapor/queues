import Jobs
import Vapor
import XCTest
@testable import Jobs

final class JobsTests: XCTestCase {
    func testVaporIntegration() throws {
        let server = try self.startServer()
        defer { server.shutdown() }
        let worker = try self.startWorker()
        defer { worker.shutdown() }
        
        FooJob.dequeuePromise = server.eventLoopGroup
            .next().makePromise(of: Void.self)
        
        let task = server.eventLoopGroup.next().scheduleTask(in: .seconds(5)) {
            return server.client.get("http://localhost:8080/foo")
        }
        let res = try task.futureResult.wait().wait()
        XCTAssertEqual(res.body?.string, "done")
        
        try FooJob.dequeuePromise!.futureResult.wait()
    }
    
    func testVaporScheduledJob() throws {
        let app = try self.startServer()
        defer { app.shutdown() }
        app.jobs.schedule(Cleanup()).hourly().at(30)
        app.jobs.schedule(Cleanup()).at(Date() + 5)
    
        XCTAssertEqual(app.jobs.configuration.scheduledStorage.count, 2)
    }
    
    private func startServer() throws -> Application {
        let app = self.setupApplication(.init(name: "worker", arguments: ["vapor", "serve"]))
        try app.start()
        return app
    }
    
    private func startWorker() throws -> Application {
        let app = self.setupApplication(.init(name: "worker", arguments: ["vapor", "jobs"]))
        try app.start()
        return app
    }
    
    private func setupApplication(_ env: Environment) -> Application {
        let app = Application(env)
        app.use(Jobs.self)
        app.jobs.use(TestDriver())
        app.jobs.add(FooJob())
        
        app.get("foo") { req in
            return req.jobs.dispatch(FooJob.self, .init(foo: "bar"))
                .map { "done" }
        }
        return app
    }
}

extension ByteBuffer {
    var string: String {
        return .init(decoding: self.readableBytesView, as: UTF8.self)
    }
}

var storage: [String: JobData] = [:]
var lock = Lock()

struct TestDriver: JobsDriver {
    func makeJobsService(with context: JobsContext) -> JobsService {
        TestService(context: context)
    }
    
    func shutdown() {
        // nothing
    }
}

struct TestService: JobsService {
    let context: JobsContext
    
    func get(key: String) -> EventLoopFuture<JobData?> {
        lock.lock()
        defer { lock.unlock() }
        let job: JobData?
        if let existing = storage[key] {
            job = existing
            storage[key] = nil
        } else {
            job = nil
        }
        return self.eventLoop.makeSucceededFuture(job)
    }
    
    func set(key: String, job: JobData) -> EventLoopFuture<Void> {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = job
        return self.eventLoop.makeSucceededFuture(())
    }
    
    func completed(key: String, job: JobData) -> EventLoopFuture<Void> {
        return self.eventLoop.makeSucceededFuture(())
    }
    
    func processingKey(key: String) -> String {
        return key
    }
    
    func requeue(key: String, job: JobData) -> EventLoopFuture<Void> {
        return self.eventLoop.makeSucceededFuture(())
    }
}

struct FooJob: Job {
    static var dequeuePromise: EventLoopPromise<Void>?
    
    struct Data: Codable {
        var foo: String
    }
    
    func dequeue(_ context: JobContext, _ data: Data) -> EventLoopFuture<Void> {
        Self.dequeuePromise!.succeed(())
        return context.eventLoop.makeSucceededFuture(())
    }
    
    func error(_ context: JobContext, _ error: Error, _ data: Data) -> EventLoopFuture<Void> {
        Self.dequeuePromise!.fail(error)
        return context.eventLoop.makeSucceededFuture(())
    }
}
