import Foundation
import Logging
import Vapor
import NIO

extension Application {
    /// The application-global ``Queues`` accessor.
    public var queues: Queues {
        .init(application: self)
    }
    
    /// Contains global configuration for queues and provides methods for registering jobs and retrieving queues.
    public struct Queues {
        /// A provider for a ``Queues`` driver.
        public struct Provider {
            let run: @Sendable (Application) -> ()

            public init(_ run: @escaping @Sendable (Application) -> ()) {
                self.run = run
            }
        }

        final class Storage: @unchecked Sendable {
            public var configuration: QueuesConfiguration
            private(set) var commands: [QueuesCommand]
            var driver: (any QueuesDriver)?

            public init(_ application: Application) {
                self.configuration = .init(logger: application.logger)
                self.commands = [.init(application: application)]
                application.asyncCommands.use(self.commands[0], as: "queues")
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
                application.queues.storage.commands.forEach { $0.shutdown() }
                application.queues.storage.driver?.shutdown()
            }
            
            func shutdownAsync(_ application: Application) async {
                for command in application.queues.storage.commands {
                    await command.asyncShutdown()
                }
                await application.queues.storage.driver?.asyncShutdown()
            }
        }

        /// The ``QueuesConfiguration`` object.
        public var configuration: QueuesConfiguration {
            get { self.storage.configuration }
            nonmutating set { self.storage.configuration = newValue }
        }

        /// The selected ``QueuesDriver``.
        public var driver: any QueuesDriver {
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

        /// Get the default ``Queue``.
        public var queue: any Queue {
            self.queue(.default)
        }

        /// Create or look up an instance of a named ``Queue``.
        ///
        /// - Parameters:
        ///   - name: The name of the queue
        ///   - logger: A logger object
        ///   - eventLoop: The event loop to run on
        public func queue(
            _ name: QueueName,
            logger: Logger? = nil,
            on eventLoop: (any EventLoop)? = nil
        ) -> any Queue {
            self.driver.makeQueue(with: .init(
                queueName: name,
                configuration: self.configuration,
                application: self.application,
                logger: logger ?? self.application.logger,
                on: eventLoop ?? self.application.eventLoopGroup.any()
            ))
        }
        
        /// Add a new queueable job.
        ///
        /// This must be called once for each job type that can be queued.
        ///
        /// - Parameter job: The job to add.
        public func add(_ job: some Job) {
            self.configuration.add(job)
        }

        /// Add a new notification hook.
        ///
        /// - Parameter hook: The hook to add.
        public func add(_ hook: some JobEventDelegate) {
            self.configuration.add(hook)
        }

        /// Choose which provider to use.
        ///
        /// - Parameter provider: The provider.
        public func use(_ provider: Provider) {
            provider.run(self.application)
        }

        /// Configure a driver.
        ///
        /// - Parameter driver: The driver
        public func use(custom driver: any QueuesDriver) {
            self.storage.driver = driver
        }

        /// Schedule a new job.
        ///
        /// - Parameter job: The job to schedule.
        public func schedule(_ job: some ScheduledJob) -> ScheduleBuilder {
            self.storage.configuration.schedule(job)
        }

        /// Starts an in-process worker to dequeue and run jobs.
        ///
        /// - Parameter queue: The queue to run the jobs on. Defaults to ``QueueName/default``.
        public func startInProcessJobs(on queue: QueueName = .default) throws {
            let inProcessJobs = QueuesCommand(application: self.application)
            
            try inProcessJobs.startJobs(on: queue)
            self.storage.add(command: inProcessJobs)
        }
        
        /// Starts an in-process worker to run scheduled jobs.
        public func startScheduledJobs() throws {
            let scheduledJobs = QueuesCommand(application: self.application)
            
            try scheduledJobs.startScheduledJobs()
            self.storage.add(command: scheduledJobs)
        }
        
        func initialize() {
            self.application.lifecycle.use(Lifecycle())
            self.application.storage[Key.self] = .init(self.application)
        }
    }
}
