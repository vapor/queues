import Foundation

public struct ScheduledJob {
    let job: AnyJob
    let recurrenceRule: RecurrenceRule

    public init(job: AnyJob, at recurrenceRule: RecurrenceRule) {
        self.job = job
        self.recurrenceRule = recurrenceRule
    }
}
