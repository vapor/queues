import Foundation
import NIO
import Vapor

final class ScheduledJobsWorker {
    let configuration: JobsConfiguration
    let logger: Logger
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
    private var isShuttingDown: Bool
    internal var scheduledJobs: [(AnyScheduledJob, Date)]
    
    init(
        configuration: JobsConfiguration,
        logger: Logger,
        on eventLoop: EventLoop
    ) {
        self.configuration = configuration
        self.eventLoop = eventLoop
        self.logger = logger
        self.shutdownPromise = self.eventLoop.makePromise()
        self.isShuttingDown = false
        self.scheduledJobs = []
    }
    
    func start() throws {
        let scheduledJobsStartDates = configuration
            .scheduledStorage
            .map { ($0, try? $0.scheduler.resolveNextDateThatSatisifiesSchedule(date: Date())) }
        
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
            self.shutdownPromise.succeed(())
        }
    }
    
    private func run(job: AnyScheduledJob, date: Date) {
        let initialDelay = TimeAmount.seconds(Int64(abs(date.timeIntervalSinceNow)))
        eventLoop.scheduleRepeatedAsyncTask(
            initialDelay: initialDelay,
            delay: .seconds(0)
        ) { task -> EventLoopFuture<Void> in
            // Cancel no matter what
            task.cancel()
            
            if self.isShuttingDown {
                self.shutdownPromise.succeed(())
            }
            
            return job.job.run(context: self.context).always { _ in
                if let nextDate = try? job.scheduler.resolveNextDateThatSatisifiesSchedule(date: date) {
                    self.scheduledJobs.append((job, nextDate))
                    self.run(job: job, date: nextDate)
                }
            }.transform(to: ())
        }
    }
    
    func shutdown() {
        self.isShuttingDown = true
    }
}
