import Jobs
import NIOConcurrencyHelpers
import Vapor
import XCTest
@testable import Jobs

final class JobsTests: XCTestCase {
    func testVaporIntegration() throws {
        let server = try startServer()
        defer { try! server.syncShutdownGracefully() }
        let worker = try startWorker()
        defer { try! worker.syncShutdownGracefully() }

        let task = server.eventLoop.next().scheduleTask(in: .seconds(5)) {
            try server.client().get("http://localhost:8080/foo")
        }

        let res = try task.futureResult.wait().wait()
        let bodyData = try XCTUnwrap(res.http.body.data)
        let responseBody = String(data: bodyData, encoding: .utf8)
        XCTAssertEqual(responseBody, "done")
    }

    func testVaporScheduledJob() throws {
        let app = try startServer()
        defer { try! app.syncShutdownGracefully() }
        let jobsConfig = try app.make(JobsConfiguration.self)

        try app.jobs.schedule(Cleanup()).hourly().at(30)
        try app.jobs.schedule(Cleanup()).at(Date() + 5)

        XCTAssertEqual(jobsConfig.scheduledStorage.count, 2)
    }

    private func startServer() throws -> Application {
        let app = try setupApplication(.init(name: "worker", isRelease: false, arguments: ["vapor", "serve"]))
        _ = app.asyncRun()
        return app
    }

    private func startWorker() throws -> Application {
        let app = try setupApplication(.init(name: "worker", isRelease: false, arguments: ["vapor", "jobs"]))
        _ = app.asyncRun()
        return app
    }

    private func setupApplication(_ env: Environment) throws -> Application {
        var services = Services.default()
        services.register(JobsDriver.self) { container in
            TestDriver(on: container.eventLoop)
        }

        try services.register(JobsProvider())

        var commandConfig = CommandConfig.default()
        commandConfig.useJobsCommands()
        services.register(commandConfig)

        let router = EngineRouter.default()
        router.get("foo") { req in
            req.jobs.dispatch(FooJob.self, .init(foo: "bar")).map { "done" }
        }
        services.register(router, as: Router.self)

        let app = try Application(environment: env, services: services)
        try app.jobs.add(FooJob())

        return app
    }
}

extension ByteBuffer {
    var string: String {
        return .init(decoding: readableBytesView, as: UTF8.self)
    }
}

var storage: [String: JobStorage] = [:]
var lock = Lock()

final class TestDriver: JobsDriver {
    var eventLoopGroup: EventLoopGroup

    init(on eventLoopGroup: EventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
    }

    func get(key: String, eventLoop: JobsEventLoopPreference) -> EventLoopFuture<JobStorage?> {
        lock.lock()
        defer { lock.unlock() }
        let job: JobStorage?
        if let existing = storage[key] {
            job = existing
            storage[key] = nil
        } else {
            job = nil
        }
        return eventLoop.delegate(for: eventLoopGroup)
            .future(job)
    }

    func set(key: String, job: JobStorage, eventLoop: JobsEventLoopPreference) -> EventLoopFuture<Void> {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = job
        return eventLoop.delegate(for: eventLoopGroup)
            .future(())
    }

    func completed(key: String, job: JobStorage, eventLoop: JobsEventLoopPreference) -> EventLoopFuture<Void> {
        return eventLoop.delegate(for: eventLoopGroup)
            .future(())
    }

    func processingKey(key: String) -> String {
        return key
    }

    func requeue(key: String, job: JobStorage, eventLoop: JobsEventLoopPreference) -> EventLoopFuture<Void> {
        return eventLoop.delegate(for: eventLoopGroup)
            .future(())
    }
}

class FooJob: Job {
    struct Data: Codable {
        var foo: String
    }

    func dequeue(_ context: JobContext, _ data: Data) -> EventLoopFuture<Void> {
        return context.eventLoop.future(())
    }

    func error(_ context: JobContext, _ error: Error, _ data: Data) -> EventLoopFuture<Void> {
        return context.eventLoop.future()
    }
}
