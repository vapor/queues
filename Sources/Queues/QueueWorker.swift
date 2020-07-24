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
        self.queue.pop().flatMap { id in
            //No job found, go to the next iteration
            guard let id = id else {
                return self.queue.eventLoop.makeSucceededFuture(())
            }
            return self.queue.get(id).flatMap { data in
                // If the job has a delay, we must check to make sure we can execute.
                // If the delay has not passed yet, requeue the job
                if let delay = data.delayUntil, delay >= Date() {
                    return self.queue.push(id)
                }

                guard let job = self.queue.configuration.jobs[data.jobName] else {
                    self.queue.logger.error("No job named \(data.jobName) is registered")
                    return self.queue.eventLoop.makeSucceededFuture(())
                }

                self.queue.logger.info("Dequeing job", metadata: [
                    "job_id": .string(id.string),
                    "job_name": .string(data.jobName),
                    "queue": .string(self.queue.queueName.string)
                ])
                var logger = self.queue.logger
                logger[metadataKey: "job_id"] = .string(id.string)
                return self.run(
                    id: id,
                    name: data.jobName,
                    job: job,
                    payload: data.payload,
                    logger: logger,
                    remainingTries: data.maxRetryCount
                ).flatMap {
                    self.queue.clear(id)
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
        remainingTries: Int
    ) -> EventLoopFuture<Void> {
        let futureJob = job._dequeue(self.queue.context, payload: payload)
        return futureJob.map { complete in
            return complete
        }.flatMapError { error in
            if remainingTries == 0 {
                logger.error("Job failed with error: \(error)", metadata: [
                    "job_id": .string(id.string),
                    "job_name": .string(name),
                    "queue": .string(self.queue.queueName.string)
                ])
                return job._error(self.queue.context, error, payload: payload)
            } else {
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
                    remainingTries: remainingTries - 1
                )
            }
        }
    }
}
