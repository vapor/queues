import Foundation
import Vapor
import NIO

/// A provider used to setup the `Jobs` package
public struct JobsProvider: Provider {
    /// The key to use for calling the command. Defaults to `jobs`
    public var commandKey: String
    
    /// Initializes the `Jobs` package
    public init(commandKey: String = "jobs") {
        self.commandKey = commandKey
    }

    /// See `Provider`.`register(_ app:)`
    public func register(_ app: Application) {
        app.register(JobsService.self) { app in
            return ApplicationJobsService(
                configuration: app.make(),
                driver: app.make(),
                logger: app.make(),
                eventLoopPreference: .indifferent
            )
        }

        app.register(JobsConfiguration.self) { _ in
            return JobsConfiguration()
        }

        app.register(singleton: JobsCommand.self, boot: { app in
            return .init(application: app)
        }, shutdown: { jobs in
            jobs.shutdown()
        })
        
        app.register(extension: CommandConfiguration.self) { configuration, a in
            configuration.use(a.make(JobsCommand.self), as: self.commandKey)
        }
    }
}

public struct ApplicationJobs {
    private let application: Application
    
    public init(for application: Application) {
        self.application = application
    }
    
    public func add<J>(_ job: J) where J: Job {
        application.register(extension: JobsConfiguration.self) { jobs, app in
            jobs.add(job)
        }
    }
    
    public func driver(_ driver: JobsDriver) {
        application.register(instance: driver)
    }
    
    public func schedule<J>(_ job: J) -> ScheduleBuilder
        where J: ScheduledJob
    {
        let builder = ScheduleBuilder()
        application.register(extension: JobsConfiguration.self) { jobs, app in
            _ = jobs.schedule(job, builder: builder)
        }
        return builder
    }
    
    public func schedule<J>(_ job: J, at date: Date) where J: ScheduledJob {
        application.register(extension: JobsConfiguration.self) { jobs, app in
            jobs.schedule(job, at: date)
        }
    }
}

extension Application {
    public var jobs: ApplicationJobs {
        return ApplicationJobs(for: self)
    }
}
