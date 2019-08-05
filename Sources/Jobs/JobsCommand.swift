import Foundation
import Vapor

/// The command to start the Queue job
public final class JobsCommand: Command {
    /// See `Command.signature`
    public let signature = Signature()
    
    /// See `Command.Signature`
    public struct Signature: CommandSignature {
        let queue = Option<String>(name: "queue", type: .value)
        let scheduledJobs = Option<Bool>(name: "scheduled", type: .flag)
    }
    
    /// See `Command.help`
    public var help: String {
        return "Runs queued worker jobs"
    }

    private let application: Application
    private var workers: [(JobsWorker, Container)]?
    private var scheduledWorkers: [(ScheduledJobsWorker, Container)]?

    internal init(application: Application) {
        self.application = application
    }

    public func run(using context: CommandContext<JobsCommand>) throws {
        let signalQueue = DispatchQueue(label: "vapor.jobs.command.SignalHandlingQueue")
        
        //SIGTERM
        let termSignalSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: signalQueue)
        termSignalSource.setEventHandler {
            print("Shutting down remaining jobs.")
            self.shutdown()
            termSignalSource.cancel()
        }
        signal(SIGTERM, SIG_IGN)
        termSignalSource.resume()
        
        //SIGINT
        let intSignalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: signalQueue)
        intSignalSource.setEventHandler {
            print("Shutting down remaining jobs.")
            self.shutdown()
            intSignalSource.cancel()
        }
        signal(SIGINT, SIG_IGN)
        intSignalSource.resume()
        
        // allow for this command to be stopped programmatically
        self.application.running = .init(stop: {
            self.shutdown()
        })

        
        let isScheduled = context.option(\.scheduledJobs) ?? false
        
        if isScheduled {
            context.console.info("Starting scheduled jobs worker")
            try self.startScheduledWorker().wait()
        } else {
            let queue: JobsQueue = context.option(\.queue)
                .flatMap { .init(name: $0) } ?? .default
            context.console.info("Starting jobs worker")
            try self.startJobsWorker(on: queue).wait()
        }
    }

    private func startJobsWorker(on queue: JobsQueue) throws -> EventLoopFuture<Void> {
        var workers: [(JobsWorker, Container)] = []
        for eventLoop in self.application.eventLoopGroup.makeIterator() {
            let container = try self.application.makeContainer(on: eventLoop).wait()
            let worker: JobsWorker
            do {
                worker = try container.make(JobsWorker.self)
            } catch {
                container.shutdown()
                throw error
            }
            worker.start(on: queue)
            workers.append((worker, container))
        }

        self.workers = workers
        return .andAllComplete(
            workers.map { $0.0.onShutdown },
            on: self.application.eventLoopGroup.next()
        )
    }
    
    private func startScheduledWorker() throws -> EventLoopFuture<Void> {
        var scheduledWorkers: [(ScheduledJobsWorker, Container)] = []
        
        for eventLoop in self.application.eventLoopGroup.makeIterator() {
            let container = try self.application.makeContainer(on: eventLoop).wait()
            let worker: ScheduledJobsWorker
            do {
                worker = try container.make(ScheduledJobsWorker.self)
            } catch {
                container.shutdown()
                throw error
            }
            
            try worker.start()
            scheduledWorkers.append((worker, container))
        }
        
        self.scheduledWorkers = scheduledWorkers
        return .andAllComplete(
            scheduledWorkers.map { $0.0.onShutdown },
            on: self.application.eventLoopGroup.next()
        )
    }

    private func shutdown() {
        if let workers = workers {
            workers.forEach { (workers, container) in
                workers.shutdown()
                container.shutdown()
            }
        }
        
        if let scheduledWorkers = scheduledWorkers {
            scheduledWorkers.forEach { (workers, container) in
                workers.shutdown()
                container.shutdown()
            }
        }
    }
}
