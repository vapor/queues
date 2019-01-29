import Vapor

public struct ScheduledJobConfig: Service {
    var scheduledJobs = [ScheduledJob]()

    public init() { }

    public mutating func add(_ ScheduledJob: ScheduledJob) {
        scheduledJobs.append(ScheduledJob)
    }
}
