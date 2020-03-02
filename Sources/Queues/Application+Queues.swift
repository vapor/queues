import Foundation
import Vapor
import NIO

extension Application {
    /// Deprecated `Jobs` object
    @available(*, unavailable, renamed: "queues")
    public var jobs: Queues {
        self.queues
    }
    
    /// The `Queues` object
    public var queues: Queues {
        .init(application: self)
    }
    
    public struct Queues {
        public struct Provider {
            let run: (Application) -> ()

            public init(_ run: @escaping (Application) -> ()) {
                self.run = run
            }
        }

        final class Storage {
            public var configuration: QueuesConfiguration
            let command: QueuesCommand
            var driver: QueuesDriver?

            public init(_ application: Application) {
                self.configuration = .init(logger: application.logger)
                self.command = .init(application: application)
                application.commands.use(self.command, as: "queues")
            }

        }

        struct Key: StorageKey {
            typealias Value = Storage
        }

        struct Lifecycle: LifecycleHandler {
            func shutdown(_ application: Application) {
                application.queues.storage.command.shutdown()
                if let driver = application.queues.storage.driver {
                    driver.shutdown()
                }
            }
        }

        public var configuration: QueuesConfiguration {
            get { self.storage.configuration }
            nonmutating set { self.storage.configuration = newValue }
        }

        public var queue: Queue {
            self.queue(.default)
        }

        public var driver: QueuesDriver {
            guard let driver = self.storage.driver else {
                fatalError("No Queues driver configured. Configure with app.queues.use(...)")
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
            _ name: QueueName,
            logger: Logger? = nil,
            on eventLoop: EventLoop? = nil
        ) -> Queue {
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
        public func use(custom driver: QueuesDriver) {
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
        public func startInProcessJobs(on queue: QueueName = .default) throws {
            try QueuesCommand(application: application, scheduled: false).startJobs(on: queue)
        }
        
        /// Starts an in-process worker to run scheduled jobs
        public func startScheduledJobs() throws {
            try QueuesCommand(application: application, scheduled: true).startScheduledJobs()
        }
        
        func initialize() {
            self.application.lifecycle.use(Lifecycle())
            self.application.storage[Key.self] = .init(application)
        }
    }
}
