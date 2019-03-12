import Vapor

public struct ScheduledJob {
    let job: AnyJob
    let recurrenceRule: RecurrenceRule

    public init(job: AnyJob, at recurrenceRule: RecurrenceRule) {
        self.job = job
        self.recurrenceRule = recurrenceRule
    }
}

public struct ScheduledJobConfig: Service {
    var scheduledJobs = [ScheduledJob]()

    public init() { }

    public mutating func add(_ ScheduledJob: ScheduledJob) {
        scheduledJobs.append(ScheduledJob)
    }
}
