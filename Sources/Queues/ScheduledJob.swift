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
    let scheduler: ScheduleBuilder
    
    init(job: ScheduledJob, scheduler: ScheduleBuilder) {
        self.job = job
        self.scheduler = scheduler
    }
}

protocol AnyScheduledJobTask {
    var done: EventLoopFuture<Void> { get }

    func cancel(promise: EventLoopPromise<Void>?)
}

extension AnyScheduledJobTask {
    func cancel() {
        cancel(promise: nil)
    }

    func syncCancel(on eventLoop: EventLoop) {
        do {
            let promise = eventLoop.makePromise(of: Void.self)
            self.cancel(promise: promise)
            try promise.futureResult.wait()
        } catch {
            print("failed cancelling repeated task \(error)")
        }
    }
}

extension AnyScheduledJob {
    typealias Task = AnyScheduledJobTask

    final class TaskImpl: Task {
        let eventLoop: EventLoop

        let done: EventLoopFuture<Void>

        var innerTask: RepeatedTask? {
            get {
                eventLoop.assertInEventLoop()
                return _innerTask
            }
            set {
                eventLoop.assertInEventLoop()
                _innerTask = newValue
            }
        }

        var isCancelled: Bool {
            get {
                eventLoop.assertInEventLoop()
                return _isCancelled
            }
            set {
                eventLoop.assertInEventLoop()
                _isCancelled = newValue
            }
        }

        private var _innerTask: RepeatedTask?
        private var _isCancelled: Bool = false

        init(
            eventLoop: EventLoop,
            done: EventLoopFuture<Void>
        ) {
            self.eventLoop = eventLoop
            self.done = done
        }

        func cancel(promise: EventLoopPromise<Void>?) {
            if eventLoop.inEventLoop {
                cancel0(promise: promise)
            } else {
                eventLoop.execute {
                    self.cancel0(promise: promise)
                }
            }
        }

        private func cancel0(promise: EventLoopPromise<Void>?) {
            eventLoop.assertInEventLoop()
            _isCancelled = true
            _innerTask?.cancel(promise: promise)
        }
    }

    func schedule(context: QueueContext) -> Task? {
        context.logger.trace("Beginning the scheduler process")

        guard let date = self.scheduler.nextDate() else {
            context.logger.debug("No date scheduled for \(self.job.name)")
            return nil
        }

        context.logger.debug("Scheduling \(self.job.name) to run at \(date)")

        let eventLoop = context.eventLoop
        let promise = eventLoop.makePromise(of: Void.self)
        let task = TaskImpl(eventLoop: eventLoop, done: promise.futureResult)

        func recurse() {
            if task.isCancelled { return }

            let nioTask = nioSchedule(eventLoop: eventLoop, date: date) {
                let now = Date()
                if now < date {
                    // It still doesn't reach scheduled date, reschedule.
                    recurse()
                    return
                }

                context.logger.trace("Running the scheduled job \(self.job.name)")
                self.job.run(context: context).cascade(to: promise)
            }

            task.innerTask = nioTask
        }

        eventLoop.execute {
            recurse()
        }

        return task
    }

    private func nioSchedule(eventLoop: EventLoop, date: Date, completion: @escaping () -> Void) -> RepeatedTask {
        return eventLoop.scheduleRepeatedTask(
            initialDelay: .microseconds(Int64(date.timeIntervalSinceNow * 1_000_000)),
            delay: .seconds(0)
        ) { (nioTask) in
            // always cancel
            nioTask.cancel()
            completion()
        }
    }
}
