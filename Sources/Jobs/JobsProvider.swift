import Foundation
import Vapor

/// A provider used to setup the `Jobs` package
public struct JobsProvider: Provider {
    /// The key to use for calling the command. Defaults to `jobs`
    public var commandKey: String

    /// Initializes the `Jobs` package
    public init(commandKey: String = "jobs") {
        self.commandKey = commandKey
    }

    /// See `Provider`.`register(_ services:)`
    public func register(_ services: inout Services) throws {
        services.register(JobsConfiguration())

        services.register(JobsService.self) { container in
            return ApplicationJobsService(
                configuration: try container.make(),
                driver: try container.make(),
                logger: try container.make(),
                eventLoopPreference: .indifferent
            )
        }

        services.register(JobsCommand.self) { container in
            return try JobsCommand(container: container)
        }
    }

    /// See `Provider`.`didBoot(_ container:)`
    public func didBoot(_ container: Container) throws -> Future<Void> {
        return .done(on: container)
    }
}

public struct ApplicationJobs {
    private let container: Container

    public init(for container: Container) {
        self.container = container
    }

    public func add<J>(_ job: J) throws where J: Job {
        let jobs = try container.make(JobsConfiguration.self)
        jobs.add(job)
    }

    public func schedule<J>(_ job: J) throws -> ScheduleBuilder
        where J: ScheduledJob
    {
        let builder = ScheduleBuilder()
        let jobs = try container.make(JobsConfiguration.self)
        jobs.schedule(job, builder: builder)
        return builder
    }
}

extension Application {
    public var jobs: ApplicationJobs {
        return ApplicationJobs(for: self)
    }
}

