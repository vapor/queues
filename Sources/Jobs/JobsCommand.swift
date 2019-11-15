import Foundation
import Vapor
import NIO

/// The command to start the Queue job
public class JobsCommand: Command, Service {
    /// See `Command`.`arguments`
    public var arguments: [CommandArgument] = []
    
    /// See `Command`.`options`
    public var options: [CommandOption] {
        return [
            CommandOption.value(name: "queue"),
            CommandOption.value(name: "scheduled")
        ]
    }

    /// See `Command`.`help`
    public var help: [String] = ["Runs queued worker jobs"]

    private let container: Container
    private var workers: [JobsWorker]?
    private var scheduledWorkers: [ScheduledJobsWorker]?
    private let scheduled: Bool

    private var isShuttingDown: Bool {
        get {
            self._lock.lock()
            defer { self._lock.unlock() }
            return self._isShuttingDown
        }
        set {
            self._lock.lock()
            defer { self._lock.unlock() }
            self._isShuttingDown = newValue
        }
    }

    private var _isShuttingDown: Bool = false
    private var _lock: NSLock

    /// Create a new `JobsCommand`
    init(container: Container, scheduled: Bool = false) throws {
        self.container = container
        self.scheduled = scheduled
        self._lock = NSLock()
    }

    /// See `Command`.`run(using:)`
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        let signalQueue = DispatchQueue(label: "vapor.jobs.command.SignalHandlingQueue")

        //SIGTERM
        let termSignalSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: signalQueue)
        termSignalSource.setEventHandler {
            print("Shutting down remaining jobs.")
            self.isShuttingDown = true
            termSignalSource.cancel()
        }
        signal(SIGTERM, SIG_IGN)
        termSignalSource.resume()

        //SIGINT
        let intSignalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: signalQueue)
        intSignalSource.setEventHandler {
            print("Shutting down remaining jobs.")
            self.isShuttingDown = true
            intSignalSource.cancel()
        }
        signal(SIGINT, SIG_IGN)
        intSignalSource.resume()


        let isScheduledFromCli = context.options["scheduled"] != nil
        if isScheduledFromCli || self.scheduled {
            context.console.info("Starting scheduled jobs worker")
            try self.startScheduledWorker()
        } else {
            let queue: JobsQueue
            if let queueName = context.options["queue"] {
                queue = .init(name: queueName)
            } else {
                queue = .default
            }

            context.console.info("Starting jobs worker")
            try self.startJobsWorker(on: queue)
        }

        return try self.container.make(EventLoopGroup.self).future()
    }

    private func startJobsWorker(on queue: JobsQueue) throws {
        var workers: [JobsWorker] = []

        let eventLoopGroup = try self.container.make(EventLoopGroup.self)
        if let iterator = eventLoopGroup.makeIterator() {
            for eventLoop in iterator {
                let worker = JobsWorker(
                    configuration: try self.container.make(),
                    driver: try self.container.make(),
                    on: eventLoop
                )
                worker.start(on: queue)
                workers.append(worker)
            }
        }

        self.workers = workers
    }

    private func startScheduledWorker() throws {
        var scheduledWorkers: [ScheduledJobsWorker] = []

        let eventLoopGroup = try self.container.make(EventLoopGroup.self)
        if let iterator = eventLoopGroup.makeIterator() {
            for eventLoop in iterator {
                let worker = ScheduledJobsWorker(
                    configuration: try self.container.make(),
                    on: eventLoop
                )
                try worker.start()
                scheduledWorkers.append(worker)
            }
        }

        self.scheduledWorkers = scheduledWorkers
    }

    public func shutdown() throws {
        var futures: [EventLoopFuture<Void>] = []

        if let workers = workers {
            workers.forEach { worker in
                worker.shutdown()
            }
            futures += workers.map { $0.onShutdown }
        }

        if let scheduledWorkers = scheduledWorkers {
            scheduledWorkers.forEach { worker in
                worker.shutdown()
            }
            futures += scheduledWorkers.map { $0.onShutdown }
        }

        let eventLoopGroup = try self.container.make(EventLoopGroup.self)
        try! EventLoopFuture<Void>
            .andAll(futures, eventLoop: eventLoopGroup.next()).wait()
    }
}

extension CommandConfig {
    /// Adds Job's commands to the `CommandConfig`. Currently add migration commands.
    ///
    ///     var commandConfig = CommandConfig.default()
    ///     commandConfig.useJobsCommands()
    ///     services.register(commandConfig)
    ///
    public mutating func useJobsCommands() {
        use(JobsCommand.self, as: "jobs")
    }
}
