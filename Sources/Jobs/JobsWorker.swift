import Foundation
import NIO
import Vapor
import NIOConcurrencyHelpers

public final class JobsWorker {
    let configuration: JobsConfiguration
    let driver: JobsDriver
    var context: JobContext {
        return .init(
            userInfo: self.configuration.userInfo,
            on: self.eventLoop
        )
    }
    let logger: Logger
    let eventLoop: EventLoop

    var onShutdown: EventLoopFuture<Void> {
        return self.shutdownPromise.futureResult
    }

    private let shutdownPromise: EventLoopPromise<Void>
    private var isShuttingDown: Atomic<Bool>
    private var repeatedTask: RepeatedTask?

    public init(
        configuration: JobsConfiguration,
        driver: JobsDriver,
        logger: Logger,
        on eventLoop: EventLoop
    ) {
        self.configuration = configuration
        self.eventLoop = eventLoop
        self.driver = driver
        self.logger = logger
        self.shutdownPromise = self.eventLoop.newPromise()
        self.isShuttingDown = .init(value: false)
    }

    public func start(on queue: JobsQueue) {
        // Schedule the repeating task
        self.repeatedTask = eventLoop.scheduleRepeatedTask(
            initialDelay: .seconds(0),
            delay: self.configuration.refreshInterval
        ) { task in
            // run task
            return self.run(on: queue).map {
                //Check if shutting down
                if self.isShuttingDown.load() {
                    task.cancel()
                    self.shutdownPromise.succeed()
                }
            }.mapIfError { error in
                self.logger.error("Job run failed: \(error)")
            }
        }
    }

    public func shutdown() {
        self.isShuttingDown.store(true)
    }

    private func run(on queue: JobsQueue) -> EventLoopFuture<Void> {
        let key = queue.makeKey(with: self.configuration.persistenceKey)

        return self.driver.get(key: key, eventLoop: .delegate(on: self.eventLoop)).flatMap { jobStorage in
            //No job found, go to the next iteration
            guard let jobStorage = jobStorage else {
                return self.eventLoop.newSucceededFuture(result: ())
            }

            // If the job has a delay, we must check to make sure we can execute. If the delay has not passed yet, requeue the job
            if let delay = jobStorage.delayUntil, delay >= Date() {
                self.logger.info("Requeing delayed Job with job_id: \(jobStorage.id) until \(delay)")
                return self.driver.requeue(
                    key: key,
                    job: jobStorage,
                    eventLoop: .delegate(on: self.eventLoop)
                )
            }

            guard let job = self.configuration.make(for: jobStorage.jobName) else {
                let error = Abort(.internalServerError)
                self.logger.error("No job named \(jobStorage.jobName) is registered")
                return self.eventLoop.newFailedFuture(error: error)
            }

            self.logger.info("Dequeing Job with job_id: \(jobStorage.id)")
            let jobRunPromise = self.eventLoop.newPromise(of: Void.self)
            self.firstJobToSucceed(
                job: job,
                jobContext: self.context,
                jobStorage: jobStorage,
                tries: jobStorage.maxRetryCount)
            .thenIfError { error in
                self.logger.error("\(error) for job_id: \(jobStorage.id)")
                return job.error(self.context, error, jobStorage)
            }.whenComplete {
                self.driver.completed(
                    key: key,
                    job: jobStorage,
                    eventLoop: .delegate(on: self.eventLoop)
                ).cascade(promise: jobRunPromise)
            }

            return jobRunPromise.futureResult
        }
    }

    private func firstJobToSucceed(
        job: AnyJob,
        jobContext: JobContext,
        jobStorage: JobStorage,
        tries: Int
    ) -> EventLoopFuture<Void> {
        let futureJob = job.anyDequeue(jobContext, jobStorage)
        return futureJob.map { complete in
            return complete
        }.thenIfError { error in
            if tries == 0 {
                return self.eventLoop.newFailedFuture(error: error)
            } else {
                return self.firstJobToSucceed(job: job, jobContext: jobContext, jobStorage: jobStorage, tries: tries - 1)
            }
        }
    }
}
