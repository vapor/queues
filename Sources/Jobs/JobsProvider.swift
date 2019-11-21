import Foundation
import Vapor
import NIO

extension Request {
    public var jobs: JobsQueue {
        self.jobs(.default)
    }
    
    public func jobs(_ queue: JobsQueueName) -> JobsQueue {
        self.application.jobs.queue(
            queue,
            logger: self.logger,
            on: self.eventLoop
        )
    }
}

public struct JobsDriverFactory {
    let factory: (Jobs) -> JobsDriver
    public init(_ factory: @escaping (Jobs) -> JobsDriver) {
        self.factory = factory
    }
}

public final class Jobs: Provider {
    public var application: Application
    
    public var configuration: JobsConfiguration
    let command: JobsCommand
    var driver: JobsDriver?

    public var queue: JobsQueue {
        self.queue(.default)
    }
    
    public func queue(_ name: JobsQueueName, logger: Logger? = nil, on eventLoop: EventLoop? = nil) -> JobsQueue {
        guard let driver = self.driver else {
            fatalError("No Jobs driver configured.")
        }
        return driver.makeQueue(
            with: .init(
                queueName: name,
                configuration: self.configuration,
                logger: logger ?? self.application.logger,
                on: eventLoop ?? self.application.eventLoopGroup.next()
            )
        )
    }
    
    public init(_ application: Application) {
        self.application = application
        self.configuration = .init(logger: application.logger)
        self.command = .init(application: application)
        self.application.commands.use(self.command, as: "jobs")
    }
    
    
    public func add<J>(_ job: J) where J: Job {
        self.configuration.add(job)
    }
    
    public func use(_ driver: JobsDriverFactory) {
        self.driver = driver.factory(self)
    }
    
    public func use(custom driver: JobsDriver) {
        self.driver = driver
    }
    
    public func schedule<J>(_ job: J) -> ScheduleBuilder
        where J: ScheduledJob
    {
        let builder = ScheduleBuilder()
        _ = self.configuration.schedule(job, builder: builder)
        return builder
    }
    
    func worker(queueName: JobsQueueName, on eventLoop: EventLoop) -> JobsWorker {
        .init(queue: self.queue(queueName, on: eventLoop))
    }
    
    func scheduledWorker(on eventLoop: EventLoop) -> ScheduledJobsWorker {
        .init(
            configuration: self.configuration,
            logger: self.application.logger,
            on: eventLoop
        )
    }

    public func shutdown() {
        self.command.shutdown()
        if let driver = self.driver {
            driver.shutdown()
        }
    }
}

extension Application {
    public var jobs: Jobs {
        self.providers.require(Jobs.self)
    }
}
