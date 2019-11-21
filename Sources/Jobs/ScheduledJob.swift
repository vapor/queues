/// Describes a job that can be scheduled and repeated
public protocol ScheduledJob {
    /// The method called when the job is run
    /// - Parameter context: A `JobContext` that can be used
    func run(context: JobContext) -> EventLoopFuture<Void>
}

class AnyScheduledJob {
    let job: ScheduledJob
    let scheduler: ScheduleBuilder
    
    init(job: ScheduledJob, scheduler: ScheduleBuilder) {
        self.job = job
        self.scheduler = scheduler
    }
}
