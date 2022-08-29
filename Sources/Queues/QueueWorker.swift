extension Queue {
    public var worker: QueueWorker {
        .init(queue: self)
    }
}

/// The worker that runs the `Job`
public struct QueueWorker {
    let queue: Queue

    init(queue: Queue) {
        self.queue = queue
    }
    
    /// Logic to run the queue
    public func run() -> EventLoopFuture<Void> {
        queue.logger.trace("Popping job from queue")
        return self.queue.pop().flatMap { id in
            //No job found, go to the next iteration
            guard let id = id else {
                self.queue.logger.trace("Did not receive ID from pop")
                return self.queue.eventLoop.makeSucceededFuture(())
            }

            self.queue.logger.trace("Received job \(id)")
            self.queue.logger.trace("Getting data for job \(id)")

            return self.queue.get(id).flatMap { data in
                var logger = self.queue.logger
                logger[metadataKey: "job_id"] = .string(id.string)

                logger.trace("Received job data for \(id): \(data)")
                // If the job has a delay, we must check to make sure we can execute.
                // If the delay has not passed yet, requeue the job
                if let delay = data.delayUntil, delay >= Date() {
                    logger.trace("Requeueing job \(id) for execution later because the delayUntil value of \(delay) has not passed yet")
                    return self.queue.push(id)
                }

                guard let job = self.queue.configuration.jobs[data.jobName] else {
                    logger.error("No job named \(data.jobName) is registered")
                    return self.queue.eventLoop.makeSucceededFuture(())
                }

                logger.trace("Sending dequeued notification hooks")

                return self.queue.configuration.notificationHooks.map {
                    $0.didDequeue(jobId: id.string, eventLoop: self.queue.eventLoop)
                }.flatten(on: self.queue.eventLoop).flatMapError { error in
                    logger.error("Could not send didDequeue notification: \(error)")
                    return self.queue.eventLoop.future()
                }.flatMap { _ in
                    logger.info("Dequeueing job", metadata: [
                        "job_id": .string(id.string),
                        "job_name": .string(data.jobName),
                        "queue": .string(self.queue.queueName.string)
                    ])

                    return self.run(
                        id: id,
                        name: data.jobName,
                        job: job,
                        payload: data.payload,
                        logger: logger,
                        remainingTries: data.maxRetryCount,
                        attempts: data.attempts,
                        jobData: data
                    )
                }
            }
        }
    }

    private func run(
        id: JobIdentifier,
        name: String,
        job: AnyJob,
        payload: [UInt8],
        logger: Logger,
        remainingTries: Int,
        attempts: Int?,
        jobData: JobData
    ) -> EventLoopFuture<Void> {
        logger.trace("Running the queue job (remaining tries: \(remainingTries)")
        let futureJob = job._dequeue(self.queue.context, id: id.string, payload: payload)
        return futureJob.flatMap { complete in
            logger.trace("Ran job successfully")
            logger.trace("Sending success notification hooks")
            return self.queue.configuration.notificationHooks.map {
                $0.success(jobId: id.string, eventLoop: self.queue.context.eventLoop)
            }.flatten(on: self.queue.context.eventLoop).flatMapError { error in
                self.queue.logger.error("Could not send success notification: \(error)")
                return self.queue.context.eventLoop.future()
            }.flatMap {
                logger.trace("Job done being run")
                return self.queue.clear(id)
            }
        }.flatMapError { error in
            logger.trace("Job failed (remaining tries: \(remainingTries)")
            if remainingTries == 0 {
                logger.error("Job failed with error: \(error)", metadata: [
                    "job_id": .string(id.string),
                    "job_name": .string(name),
                    "queue": .string(self.queue.queueName.string)
                ])

                logger.trace("Sending failure notification hooks")
                return job._error(self.queue.context, id: id.string, error, payload: payload).flatMap { _ in
                    return self.queue.configuration.notificationHooks.map {
                        $0.error(jobId: id.string, error: error, eventLoop: self.queue.context.eventLoop)
                    }.flatten(on: self.queue.context.eventLoop).flatMapError { error in
                        self.queue.logger.error("Failed to send error notification: \(error)")
                        return self.queue.context.eventLoop.future()
                    }.flatMap {
                        logger.trace("Job done being run")
                        return self.queue.clear(id)
                    }
                }
            } else {
                return self.retry(
                    id: id,
                    name: name,
                    job: job,
                    payload: payload,
                    logger: logger,
                    remainingTries: remainingTries,
                    attempts: attempts,
                    jobData: jobData,
                    error: error
                )
            }
        }
    }

    private func retry(
        id: JobIdentifier,
        name: String,
        job: AnyJob,
        payload: [UInt8],
        logger: Logger,
        remainingTries: Int,
        attempts: Int?,
        jobData: JobData,
        error: Error
    ) -> EventLoopFuture<Void> {
        let attempts = attempts ?? 0
        let delayInSeconds = job._nextRetryIn(attempt: attempts + 1)
        if delayInSeconds == -1 {
            logger.error("Job failed, retrying... \(error)", metadata: [
                "job_id": .string(id.string),
                "job_name": .string(name),
                "queue": .string(self.queue.queueName.string)
            ])
            return self.run(
                id: id,
                name: name,
                job: job,
                payload: payload,
                logger: logger,
                remainingTries: remainingTries - 1,
                attempts: attempts + 1,
                jobData: jobData
            )
        } else {
            logger.error("Job failed, retrying in \(delayInSeconds)s... \(error)", metadata: [
                "job_id": .string(id.string),
                "job_name": .string(name),
                "queue": .string(self.queue.queueName.string)
            ])
            let storage = JobData(
                payload: jobData.payload,
                maxRetryCount: remainingTries - 1,
                jobName: jobData.jobName,
                delayUntil: Date(timeIntervalSinceNow: Double(delayInSeconds)),
                queuedAt: jobData.queuedAt,
                attempts: attempts + 1
            )
            return self.queue.clear(id).flatMap {
                self.queue.set(id, to: storage)
            }.flatMap {
                self.queue.push(id)
            }
        }
    }
}
