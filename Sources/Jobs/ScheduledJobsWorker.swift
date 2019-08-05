import Foundation
import NIO
import Vapor

final class ScheduledJobsWorker {
    let configuration: JobsConfiguration
    let logger: Logger
    let eventLoop: EventLoop
    let context: JobContext
    
    var onShutdown: EventLoopFuture<Void> {
        return self.shutdownPromise.futureResult
    }
    
    private let shutdownPromise: EventLoopPromise<Void>
    private var isShuttingDown: Bool
    
    init(
        configuration: JobsConfiguration,
        context: JobContext,
        logger: Logger,
        on eventLoop: EventLoop
    ) {
        self.configuration = configuration
        self.eventLoop = eventLoop
        self.context = context
        self.logger = logger
        self.shutdownPromise = eventLoop.makePromise()
        self.isShuttingDown = false
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
                self.run(job: job.0, date: date)
            }
        }
        
        if counter == 0 {
            self.shutdownPromise.succeed(())
        }
    }
    
    private func run(job: AnyScheduledJob, date: Date) {
        let initialDelay = TimeAmount.seconds(TimeAmount.Value(abs(date.timeIntervalSinceNow)))
        eventLoop.scheduleRepeatedAsyncTask(
            initialDelay: initialDelay,
            delay: .seconds(0)
        ) { task -> EventLoopFuture<Void> in
            // Cancel no matter what
            if self.isShuttingDown {
                self.shutdownPromise.succeed(())
            }
            
            return job.job.run(context: self.context).always { _ in
                if let nextDate = try? job.scheduler.resolveNextDateThatSatisifiesSchedule(date: Date()) {
                    self.run(job: job, date: nextDate)
                }
                
                // Always cancel the task no matter what so that it gets picked up by a separate, new scheduled job
                task.cancel()
            }.transform(to: ())
        }
    }
    
    func shutdown() {
        self.isShuttingDown = true
    }
}
