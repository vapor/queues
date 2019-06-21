import Foundation
import Vapor

/// The command to start the Queue job
public final class JobsCommand: Command {
    /// See `Command.signature`
    public let signature = Signature()
    
    /// See `Command.Signature`
    public struct Signature: CommandSignature {
        let queue = Option<String>(name: "queue", type: .value)
    }
    
    /// See `Command.help`
    public var help: String {
        return "Runs queued worker jobs"
    }

    private let application: Application
    private var workers: [(JobsWorker, Container)]?


    internal init(application: Application) {
        self.application = application
    }

    public func run(using context: CommandContext<JobsCommand>) throws {
        context.console.info("Starting Jobs worker")
        let queue: JobQueue.Name = context.option(\.queue)
            .flatMap { .init(string: $0) } ?? .default

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

        try self.start(queue: queue).wait()
    }

    private func start(queue: JobQueue.Name) throws -> EventLoopFuture<Void> {
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

    private func shutdown() {
        guard let workers = self.workers else {
            fatalError("Shutdown called before start()")
        }
        workers.forEach { (workers, container) in
            workers.shutdown()
            container.shutdown()
        }
    }
}
