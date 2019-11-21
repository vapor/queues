import Foundation
import Vapor
import NIO

extension Request {
    public var jobs: JobsService {
        return RequestSpecificJobsService(
            request: self,
            service: self.application.jobs.service,
            configuration: self.application.jobs.configuration
        )
    }
}

public final class Jobs: Provider {
    public var application: Application
    
    public var configuration: JobsConfiguration
    let command: JobsCommand
    var driver: JobsDriver?
    
    public var service: JobsService {
        return ApplicationJobsService(
            configuration: self.configuration,
            driver: self.driver!,
            logger: self.application.logger,
            eventLoopPreference: .indifferent
        )
    }

    public init(_ application: Application) {
        self.application = application
        self.configuration = .init()
        self.command = .init(application: application)
        self.application.commands.use(self.command, as: "jobs")
    }
    
    
    public func add<J>(_ job: J) where J: Job {
        self.configuration.add(job)
    }
    
    public func use(_ driver: JobsDriver) {
        self.driver = driver
    }
    
    public func schedule<J>(_ job: J) -> ScheduleBuilder
        where J: ScheduledJob
    {
        let builder = ScheduleBuilder()
        _ = self.configuration.schedule(job, builder: builder)
        return builder
    }
    
    func worker(on eventLoop: EventLoop) -> JobsWorker {
        .init(
            configuration: self.configuration,
            driver: self.driver!,
            logger: self.application.logger,
            on: eventLoop
        )
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
    }
}

extension Application {
    public var jobs: Jobs {
        self.providers.require(Jobs.self)
    }
}

private struct ApplicationJobsService: JobsService {
    let configuration: JobsConfiguration
    let driver: JobsDriver
    let logger: Logger
    let eventLoopPreference: JobsEventLoopPreference
}


private struct RequestSpecificJobsService: JobsService {
    public let request: Request
    public let service: JobsService
    
    var driver: JobsDriver {
        return self.service.driver
    }
    
    var logger: Logger {
        return self.request.logger
    }
    
    var eventLoopPreference: JobsEventLoopPreference {
        return .delegate(on: self.request.eventLoop)
    }
    
    public var configuration: JobsConfiguration
    
    init(request: Request, service: JobsService, configuration: JobsConfiguration) {
        self.request = request
        self.configuration = configuration
        self.service = service
    }
}
