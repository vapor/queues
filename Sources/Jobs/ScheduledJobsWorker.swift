import Foundation
import NIO
import Vapor
import NIOConcurrencyHelpers

final class ScheduledJobsWorker {
    let configuration: JobsConfiguration
    let eventLoop: EventLoop
    var context: JobContext {
        return .init(
            userInfo: self.configuration.userInfo,
            on: self.eventLoop
        )
    }
    
    var onShutdown: EventLoopFuture<Void> {
        return self.shutdownPromise.futureResult
    }
    
    private let shutdownPromise: EventLoopPromise<Void>
    private var isShuttingDown: Atomic<Bool>
    internal var scheduledJobs: [(AnyScheduledJob, Date)]
    
    init(
        configuration: JobsConfiguration,
        on eventLoop: EventLoop
    ) {
        self.configuration = configuration
        self.eventLoop = eventLoop
        self.shutdownPromise = self.eventLoop.newPromise()
        self.isShuttingDown = .init(value: false)
        self.scheduledJobs = []
    }
    
    func start() throws {
        let scheduledJobsStartDates = configuration
            .scheduledStorage
            .map {
                return ($0, try? $0.scheduler.resolveNextDateThatSatisifiesSchedule(date: Date()))
        }
        
        var counter = 0
        for job in scheduledJobsStartDates {
            if let date = job.1 {
                // This means that it was successful in calculating the next applicable date
                counter += 1
                scheduledJobs.append((job.0, date))
                self.run(job: job.0, date: date)
            }
        }
        
        // Shut down the promise immediately if there were no jobs scheduled
        if counter == 0 {
            self.shutdownPromise.succeed()
        }
    }
    
    private func run(job: AnyScheduledJob, date: Date) {
        let initialDelay = TimeAmount.seconds(Int(abs(date.timeIntervalSinceNow)))
        eventLoop.scheduleRepeatedTask(
            initialDelay: initialDelay,
            delay: .seconds(0)
        ) { task -> EventLoopFuture<Void> in
            // Cancel no matter what
            task.cancel()
            
            if self.isShuttingDown.load() {
                self.shutdownPromise.succeed()
            }
            
            return job.job.run(context: self.context).always {
                if job.scheduler.date != nil {
                    guard let index = self.scheduledJobs.firstIndex(where: { $0.0 === job }) else { return }
                    self.scheduledJobs.remove(at: index)
                    if self.scheduledJobs.first(where: { $0.0.scheduler.date != nil }) == nil {
                        // We do not have any scheduled jobs, check for one-off jobs
                        if self.scheduledJobs.filter({ $0.0.scheduler.date != nil }).count == 0 {
                            self.shutdownPromise.succeed()
                        }
                    }
                } else {
                    if let nextDate = try? job.scheduler.resolveNextDateThatSatisifiesSchedule(date: date) {
                        self.scheduledJobs.append((job, nextDate))
                        self.run(job: job, date: nextDate)
                    }
                }
            }.transform(to: ())
        }
    }
    
    func shutdown() {
        self.isShuttingDown.store(true)
    }
}
