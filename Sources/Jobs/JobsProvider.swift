import Foundation
import Vapor
import NIO

/// A provider used to setup the `Jobs` package
public struct JobsProvider: Provider {
    /// Initializes the `Jobs` package
    public init() { }

    /// See `Provider`.`register(_ services:)`
    public func register(_ s: inout Services) {
        s.register(JobsService.self) { c in
            return try JobsService(configuration: c.make(), driver: c.make())
        }

        s.register(JobsConfiguration.self) { container in
            return JobsConfiguration()
        }

        s.register(JobsCommand.self) { c in
            return try .init(application: c.make())
        }
        
        s.register(JobsWorker.self) { c in
            return try .init(
                configuration: c.make(),
                driver: c.make(),
                context: c.make(),
                logger: c.make(),
                on: c.eventLoop
            )
        }
        
        s.register(ScheduledJobsWorker.self) { c in
            return try .init(
                configuration: c.make(),
                context: c.make(),
                logger: c.make(),
                on: c.eventLoop
            )
        }

        s.register(JobContext.self) { c in
            return .init(eventLoop: c.eventLoop)
        }

        s.extend(CommandConfiguration.self) { configuration, c in
            try configuration.use(c.make(JobsCommand.self), as: "jobs")
        }
    }
}
