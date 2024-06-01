import NIOCore
import Foundation
import Logging

/// Describes a job that can be scheduled and repeated
public protocol ScheduledJob: Sendable {
    var name: String { get }
    /// The method called when the job is run
    /// - Parameter context: A `JobContext` that can be used
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
    }

    func schedule(context: QueueContext) -> Task? {
        var logger_ = context.logger
        logger_[metadataKey: "job-name"] = "\(self.job.name)"
        let logger = logger_
        
        logger.trace("Beginning the scheduler process")
        
        guard let date = self.scheduler.nextDate() else {
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
        return .init(task: task, done: promise.futureResult)
    }
}
