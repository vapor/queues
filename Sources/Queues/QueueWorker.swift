import Dispatch
import Foundation
import Logging
import Metrics
import NIOCore

extension Queue {
    public var worker: QueueWorker {
        .init(queue: self)
    }
}

/// The worker that runs ``Job``s.
public struct QueueWorker: Sendable {
    let queue: any Queue

    /// Run the queue until there is no more work to be done.
    /// This is a thin wrapper for ELF-style callers.
    public func run() -> EventLoopFuture<Void> {
        self.queue.eventLoop.makeFutureWithTask {
            try await self.run()
        }
    }

    /// Run the queue until there is no more work to be done.
    /// This is the main async entrypoint for a queue worker.
    public func run() async throws {
        while try await self.runOneJob() {}
    }

    /// Pop a job off the queue and try to run it. If no jobs are available, do
    /// nothing. Returns whether a job was run.
    private func runOneJob() async throws -> Bool {
        var logger = self.queue.logger
        logger[metadataKey: "queue"] = "\(self.queue.queueName.string)"
        logger.trace("Popping job from queue")

        guard let id = try await self.queue.pop().get() else {
            // No job found, go around again.
            logger.trace("No pending jobs")
            return false
        }

        logger[metadataKey: "job-id"] = "\(id.string)"
        logger.trace("Found pending job")

        let data = try await self.queue.get(id).get()
        logger.trace("Received job data", metadata: ["job-data": "\(data)"])
        logger[metadataKey: "job-name"] = "\(data.jobName)"

        guard let job = self.queue.configuration.jobs[data.jobName] else {
            logger.warning("No job with the desired name is registered, discarding")
            try await self.queue.clear(id).get()
            return false
        }

        // If the job has a delay that isn't up yet, requeue it.
        guard (data.delayUntil ?? .distantPast) < Date() else {
            logger.trace("Job is delayed, requeueing for later execution", metadata: ["delayed-until": "\(data.delayUntil ?? .distantPast)"])
            try await self.queue.push(id).get()
            return false
        }

        await self.queue.sendNotification(of: "dequeue", logger: logger) {
            try await $0.didDequeue(jobId: id.string, eventLoop: self.queue.eventLoop).get()
        }

        Meter(
            label: "jobs.in.progress.meter", 
            dimensions: [("queueName", self.queue.queueName.string)]
        ).increment()

        try await self.runOneJob(id: id, job: job, jobData: data, logger: logger)
        return true
    }

    private func runOneJob(id: JobIdentifier, job: any AnyJob, jobData: JobData, logger: Logger) async throws {
        let startTime = DispatchTime.now().uptimeNanoseconds
        logger.info("Dequeing and running job", metadata: ["attempt": "\(jobData.currentAttempt)", "retries-left": "\(jobData.remainingAttempts)"])
        do {
            try await job._dequeue(self.queue.context, id: id.string, payload: jobData.payload).get()

            logger.trace("Job ran successfully", metadata: ["attempts-made": "\(jobData.currentAttempt)"])
            self.updateMetrics(for: jobData.jobName, startTime: startTime, queue: self.queue)
            await self.queue.sendNotification(of: "success", logger: logger) {
                try await $0.success(jobId: id.string, eventLoop: self.queue.context.eventLoop).get()
            }
        } catch {
            if jobData.remainingAttempts > 0 {
                // N.B.: `return` from here so we don't clear the job data.
                return try await self.retry(id: id, job: job, jobData: jobData, error: error, logger: logger)
            } else {
                logger.warning("Job failed, no retries remaining", metadata: ["error": "\(error)", "attempts-made": "\(jobData.currentAttempt)"])
                self.updateMetrics(for: jobData.jobName, startTime: startTime, queue: self.queue, error: error)

                try await job._error(self.queue.context, id: id.string, error, payload: jobData.payload).get()
                await self.queue.sendNotification(of: "failure", logger: logger) {
                    try await $0.error(jobId: id.string, error: error, eventLoop: self.queue.context.eventLoop).get()
                }
            }
        }
        try await self.queue.clear(id).get()
    }

    private func retry(id: JobIdentifier, job: any AnyJob, jobData: JobData, error: any Error, logger: Logger) async throws {
        let delay = Swift.max(0, job._nextRetryIn(attempt: jobData.currentAttempt))
        let updatedData = JobData(
            payload: jobData.payload,
            maxRetryCount: jobData.maxRetryCount,
            jobName: jobData.jobName,
            delayUntil: .init(timeIntervalSinceNow: Double(delay)),
            queuedAt: .init(),
            attempts: jobData.currentAttempt
        )

        logger.warning("Job failed, retrying", metadata: [
            "retry-delay": "\(delay)", "error": "\(error)", "next-attempt": "\(updatedData.currentAttempt)", "retries-left": "\(updatedData.remainingAttempts)",
        ])
        try await self.queue.clear(id).get()
        try await self.queue.set(id, to: updatedData).get()
        try await self.queue.push(id).get()
    }

    private func updateMetrics(
        for jobName: String,
        startTime: UInt64,
        queue: any Queue,
        error: (any Error)? = nil
    ) {
        Timer(
            label: "\(jobName).jobDurationTimer",
            dimensions: [
                ("success", error == nil ? "true" : "false"),
                ("jobName", jobName),
            ],
            preferredDisplayUnit: .milliseconds
        ).recordNanoseconds(DispatchTime.now().uptimeNanoseconds - startTime)

        if error != nil {
            Counter(
                label: "error.completed.jobs.counter",
                dimensions: [("queueName", queue.queueName.string)]
            ).increment()
        } else {
            Counter(
                label: "success.completed.jobs.counter",
                dimensions: [("queueName", queue.queueName.string)]
            ).increment()
        }

        Meter(
            label: "jobs.in.progress.meter",
            dimensions: [("queueName", queue.queueName.string)]
        ).decrement()
    }
}
