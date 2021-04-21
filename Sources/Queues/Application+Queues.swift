import Foundation
import Vapor
import NIO

extension Application {
    /// The `Queues` object
    public var queues: Queues {
        .init(application: self)
    }

    /// Represents a `Queues` configuration object
    public struct Queues {

        /// The provider of the `Queues` configuration
        public struct Provider {
            let run: (Application) -> ()

            public init(_ run: @escaping (Application) -> ()) {
                self.run = run
            }
        }

        final class Storage {
            public var configuration: QueuesConfiguration
            private (set) var commands: [QueuesCommand]
            var driver: QueuesDriver?

            public init(_ application: Application) {
                self.configuration = .init(logger: application.logger)
                let command: QueuesCommand = .init(application: application)
                self.commands = [command]
                application.commands.use(command, as: "queues")
            }

            public func add(command: QueuesCommand) {
                self.commands.append(command)
            }
        }

        struct Key: StorageKey {
            typealias Value = Storage
        }

        struct Lifecycle: LifecycleHandler {
            func shutdown(_ application: Application) {
                application.queues.storage.commands.forEach({$0.shutdown()})
                if let driver = application.queues.storage.driver {
                    driver.shutdown()
                }
            }
        }

        /// The `QueuesConfiguration` object
        public var configuration: QueuesConfiguration {
            get { self.storage.configuration }
            nonmutating set { self.storage.configuration = newValue }
        }

        /// Returns the default `Queue`
        public var queue: Queue {
            self.queue(.default)
        }

        /// The selected `QueuesDriver`
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

        public let application: Application

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

        /// Adds a new notification hook
        /// - Parameter hook: The hook object to add
        public func add<N>(_ hook: N) where N: JobEventDelegate {
            self.configuration.add(hook)
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
        public func schedule<J>(_ job: J) -> ScheduleContainer
        where J: ScheduledJob
        {
            let container = ScheduleContainer(job: job)
            self.storage.configuration.schedule(container: container)
            return container
        }

        /// Starts an in-process worker to dequeue and run jobs
        /// - Parameter queue: The queue to run the jobs on. Defaults to `default`
        public func startInProcessJobs(on queue: QueueName = .default) throws {
            let inProcessJobs = QueuesCommand(application: application, scheduled: false)
            try inProcessJobs.startJobs(on: queue)
            self.storage.add(command: inProcessJobs)
        }

        /// Starts an in-process worker to run scheduled jobs
        public func startScheduledJobs() throws {
            let scheduledJobs = QueuesCommand(application: application, scheduled: true)
            try scheduledJobs.startScheduledJobs()
            self.storage.add(command: scheduledJobs)
        }

        func initialize() {
            self.application.lifecycle.use(Lifecycle())
            self.application.storage[Key.self] = .init(application)
        }
    }
}
