import Foundation
import NIO
import Vapor

final class JobsWorker {
    let configuration: JobsConfiguration
    let driver: JobsDriver
    let context: JobContext
    let logger: Logger
    let eventLoop: EventLoop

    var onShutdown: EventLoopFuture<Void> {
        return self.shutdownPromise.futureResult
    }

    private let shutdownPromise: EventLoopPromise<Void>
    private var isShuttingDown: Bool
    private var repeatedTask: RepeatedTask?

    init(
        configuration: JobsConfiguration,
        driver: JobsDriver,
        context: JobContext,
        logger: Logger,
        on eventLoop: EventLoop
    ) {
        self.configuration = configuration
        self.driver = driver
        self.context = context
        self.eventLoop = eventLoop
        self.logger = logger
        self.shutdownPromise = eventLoop.makePromise()
        self.isShuttingDown = false
    }

    func start(on queue: JobsQueue) {
        // Schedule the repeating task
        self.repeatedTask = eventLoop.scheduleRepeatedAsyncTask(
            initialDelay: .seconds(0),
            delay: self.configuration.refreshInterval
        ) { task in
            // run task
            return self.run(on: queue).map {
                //Check if shutting down
                if self.isShuttingDown {
                    task.cancel()
                    self.shutdownPromise.succeed(())
                }
            }
        }
    }

    func shutdown() {
        self.isShuttingDown = true
    }

    private func run(on queue: JobsQueue) -> EventLoopFuture<Void> {
        let key = queue.makeKey(with: self.configuration.persistenceKey)
        self.logger.debug("Jobs worker running \(key)")
        return self.driver.get(key: key).flatMap { jobStorage in
            //No job found, go to the next iteration
            guard let jobStorage = jobStorage else {
                return self.eventLoop.makeSucceededFuture(())
            }

            // If the job has a delay, we must check to make sure we can execute
            if let delay = jobStorage.delayUntil {
                guard delay >= Date() else {
                    // The delay has not passed yet, requeue the job
                    return self.driver.requeue(key: key, jobStorage: jobStorage)
                }
            }

            guard let job = self.configuration.make(for: jobStorage.jobName) else {
                let error = Abort(.internalServerError)
                self.logger.error("No job named \(jobStorage.jobName) is registered")
                return self.eventLoop.makeFailedFuture(error)
            }

            self.logger.info("Dequeing Job job_id=[\(jobStorage.id)]")
            let jobRunPromise = self.eventLoop.makePromise(of: Void.self)
            self.firstJobToSucceed(
                job: job,
                jobContext: self.context,
                jobStorage: jobStorage,
                tries: jobStorage.maxRetryCount)
            .flatMapError { error in
                self.logger.error("Error: \(error) job_id=[\(jobStorage.id)]")
                return job.error(self.context, error, jobStorage)
            }.whenComplete { _ in
                self.driver.completed(key: key, jobStorage: jobStorage)
                    .cascade(to: jobRunPromise)
            }

            return jobRunPromise.futureResult
        }
    }

    private func firstJobToSucceed(job: AnyJob,
                                   jobContext: JobContext,
                                   jobStorage: JobStorage,
                                   tries: Int) -> EventLoopFuture<Void>
    {
        
        let futureJob = job.anyDequeue(jobContext, jobStorage)
        return futureJob.map { complete in
            return complete
        }.flatMapError { error in
            if tries == 0 {
                return self.eventLoop.makeFailedFuture(error)
            } else {
                return self.firstJobToSucceed(job: job, jobContext: jobContext, jobStorage: jobStorage, tries: tries - 1)
            }
        }
    }
}
