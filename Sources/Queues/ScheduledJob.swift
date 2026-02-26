import NIOCore
import Foundation
import Logging

/// Describes a job that can be scheduled and repeated
public protocol ScheduledJob: Sendable {
    var name: String { get }
    
    /// The method called when the job is run.
    ///
    /// - Parameter context: The ``QueueContext``.
    func run(context: QueueContext) -> EventLoopFuture<Void>
}

extension ScheduledJob {
    public var name: String { "\(Self.self)" }
}

final class AnyScheduledJob: Sendable {
    let job: any ScheduledJob
    let scheduler: ScheduleBuilder
    
    init(job: any ScheduledJob, scheduler: ScheduleBuilder) {
        self.job = job
        self.scheduler = scheduler
    }

    struct Task: Sendable {
        let task: RepeatedTask
        let done: EventLoopFuture<Void>
        let scheduledDate: Date
    }

    /// Schedule the next run of this job.
    ///
    /// - Parameters:
    ///   - context: The queue context.
    ///   - previousDate: The date this job was last scheduled to run. When provided,
    ///     `nextDate` is calculated relative to this date rather than `Date()`, which
    ///     prevents a double-fire caused by timer jitter on some platforms (e.g.
    ///     Firecracker microVMs on Fly.io) where the NIO timer fires a fraction of a
    ///     second early.  If the timer fires at 19:59:59.8 instead of 20:00:00, and we
    ///     then call `nextDate(current: Date())`, we get back 20:00:00 (still in the
    ///     future) and the job fires again.  By passing the originally-scheduled date
    ///     instead, `nextDate` correctly advances to the following occurrence.
    func schedule(context: QueueContext, after previousDate: Date? = nil) -> Task? {
        var logger_ = context.logger
        logger_[metadataKey: "job-name"] = "\(self.job.name)"
        let logger = logger_

        logger.trace("Beginning the scheduler process")

        // Use the previously-scheduled date as the reference point so that small
        // clock-jitter cannot cause the same occurrence to be returned twice.
        let searchFrom = previousDate ?? Date()
        guard let date = self.scheduler.nextDate(current: searchFrom) else {
            logger.debug("Scheduler returned no date")
            return nil
        }
        logger.debug("Job scheduled", metadata: ["scheduled-date": "\(date)"])

        let promise = context.eventLoop.makePromise(of: Void.self)
        let task = context.eventLoop.scheduleRepeatedTask(
            initialDelay: .microseconds(Int64(date.timeIntervalSinceNow * 1_000_000)), delay: .zero
        ) { task in
            // always cancel
            task.cancel()
            logger.trace("Running scheduled job")
            self.job.run(context: context).cascade(to: promise)
        }
        return .init(task: task, done: promise.futureResult, scheduledDate: date)
    }
}

