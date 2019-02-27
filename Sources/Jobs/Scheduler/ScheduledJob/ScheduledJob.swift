import Foundation

public struct ScheduledJob {
    let job: Job
    let recurrenceRule: RecurrenceRule

    public init(job: Job, at recurrenceRule: RecurrenceRule) {
        self.job = job
        self.recurrenceRule = recurrenceRule
    }
}
