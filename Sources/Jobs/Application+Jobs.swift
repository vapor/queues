import Foundation
import Vapor
import NIO

extension Application {
    
    /// The `Jobs` object
    public var jobs: Jobs {
        .init(application: self)
    }
    
    public struct Jobs {
        public struct Provider {
            let run: (Application) -> ()

            public init(_ run: @escaping (Application) -> ()) {
                self.run = run
            }
        }

        final class Storage {
            public var configuration: JobsConfiguration
            let command: JobsCommand
            var driver: JobsDriver?

            public init(_ application: Application) {
                self.configuration = .init(logger: application.logger)
                self.command = .init(application: application)
                application.commands.use(self.command, as: "jobs")
            }

        }

        struct Key: StorageKey {
            typealias Value = Storage
        }

        struct Lifecycle: LifecycleHandler {
            func shutdown(_ application: Application) {
                application.jobs.storage.command.shutdown()
                if let driver = application.jobs.storage.driver {
                    driver.shutdown()
                }
            }
        }

        public var configuration: JobsConfiguration {
            get { self.storage.configuration }
            nonmutating set { self.storage.configuration = newValue }
        }

        public var queue: JobsQueue {
            self.queue(.default)
        }

        public var driver: JobsDriver {
            guard let driver = self.storage.driver else {
                fatalError("No Jobs driver configured. Configure with app.jobs.use(...)")
            }
            return driver
        }

        var storage: Storage {
            if self.application.storage[Key.self] == nil {
                self.initialize()
            }
            return self.application.storage[Key.self]!
        }

        let application: Application

        /// Returns a `JobsQueue`
        /// - Parameters:
        ///   - name: The name of the queue
        ///   - logger: A logger object
        ///   - eventLoop: The event loop to run on
        public func queue(
            _ name: JobsQueueName,
            logger: Logger? = nil,
            on eventLoop: EventLoop? = nil
        ) -> JobsQueue {
            return self.driver.makeQueue(
                with: .init(
                    queueName: name,
                    configuration: self.configuration,
                    application: self.application,
                    logger: logger ?? self.application.logger,
                    on: eventLoop ?? self.application.eventLoopGroup.next()
                )
            )
        }
        
        /// Adds a new queued job
        /// - Parameter job: The job to add
        public func add<J>(_ job: J) where J: Job {
            self.configuration.add(job)
        }

        /// Choose which provider to use
        /// - Parameter provider: The provider
        public func use(_ provider: Provider) {
            provider.run(self.application)
        }

        /// Choose which driver to use
        /// - Parameter driver: The driver
        public func use(custom driver: JobsDriver) {
            self.storage.driver = driver
        }

        /// Schedule a new job
        /// - Parameter job: The job to schedule
        public func schedule<J>(_ job: J) -> ScheduleBuilder
            where J: ScheduledJob
        {
            let builder = ScheduleBuilder()
            _ = self.storage.configuration.schedule(job, builder: builder)
            return builder
        }

        /// Starts an in-process worker to dequeue and run jobs
        /// - Parameter queue: The queue to run the jobs on. Defaults to `default`
        public func startInProcessJobs(on queue: JobsQueueName = .default) throws {
            try JobsCommand(application: application, scheduled: false).startJobs(on: queue)
        }
        
        /// Starts an in-process worker to run scheduled jobs
        public func startScheduledJobs() throws {
            try JobsCommand(application: application, scheduled: true).startScheduledJobs()
        }
        
        func initialize() {
            self.application.lifecycle.use(Lifecycle())
            self.application.storage[Key.self] = .init(application)
        }
    }
}
