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

extension Application {
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
                print("shutdown")
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

        public func queue(
            _ name: JobsQueueName,
            logger: Logger? = nil,
            on eventLoop: EventLoop? = nil
        ) -> JobsQueue {
            return self.driver.makeQueue(
                with: .init(
                    queueName: name,
                    configuration: self.configuration,
                    logger: logger ?? self.application.logger,
                    on: eventLoop ?? self.application.eventLoopGroup.next()
                )
            )
        }

        public func add<J>(_ job: J) where J: Job {
            self.configuration.add(job)
        }

        public func use(_ provider: Provider) {
            provider.run(self.application)
        }

        public func use(custom driver: JobsDriver) {
            self.storage.driver = driver
        }

        public func schedule<J>(_ job: J) -> ScheduleBuilder
            where J: ScheduledJob
        {
            let builder = ScheduleBuilder()
            _ = self.storage.configuration.schedule(job, builder: builder)
            return builder
        }

        func initialize() {
            self.application.lifecycle.use(Lifecycle())
            self.application.storage[Key.self] = .init(application)
        }
    }
}
