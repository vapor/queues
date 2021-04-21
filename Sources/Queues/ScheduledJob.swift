import class NIO.RepeatedTask

/// Describes a job that can be scheduled and repeated
public protocol ScheduledJob {
    var name: String { get }
    /// The method called when the job is run
    /// - Parameter context: A `JobContext` that can be used
    func run(context: QueueContext) -> EventLoopFuture<Void>
}

extension ScheduledJob {
    public var name: String { "\(Self.self)" }
}

class AnyScheduledJob {
    let job: ScheduledJob
    let scheduler: ScheduleContainer.Builder
    
    init(job: ScheduledJob, scheduler: ScheduleContainer.Builder) {
        self.job = job
        self.scheduler = scheduler
    }
}

extension AnyScheduledJob {
    struct Task {
        let task: RepeatedTask
        let done: EventLoopFuture<Void>
    }
    
    func schedule(context: QueueContext) -> Task? {
        context.logger.trace("Beginning the scheduler process")
        guard let date = self.scheduler._nextDate() else {
            context.logger.debug("No date scheduled for \(self.job.name)")
            return nil
        }
        context.logger.debug("Scheduling \(self.job.name) to run at \(date)")
        let promise = context.eventLoop.makePromise(of: Void.self)
        let task = context.eventLoop.scheduleRepeatedTask(
            initialDelay: .nanoseconds(Int64(date.timeIntervalSinceNow * 1000 * 1000 * 1000)),
            delay: .zero
        ) { task in
            // always cancel
            task.cancel()
            context.logger.trace("Running the scheduled job \(self.job.name)")
            self.job.run(context: context).cascade(to: promise)
        }
        return .init(task: task, done: promise.futureResult)
    }
}
