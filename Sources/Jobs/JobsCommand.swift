import Foundation
import Vapor

public struct JobsCommand: Command {
    public var arguments: [CommandArgument] = []
    public var options: [CommandOption] {
        return [
            CommandOption.value(name: "queue")
        ]
    }

    public var help: [String] = ["Runs queued worker jobs"]
    
    public init() { }
    
    public func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        let container = context.container
        let eventLoop = container.eventLoop
        
        let queueService = try container.make(QueueService.self)
        let promise = eventLoop.newPromise(Void.self)
        let jobContext = JobContext()
        let console = context.console
        let queue = QueueType(name: context.options["queue"] ?? QueueType.default.name)
        
        let key = queue.makeKey(with: queueService.persistenceKey)
        _ = eventLoop.scheduleRepeatedTask(initialDelay: .seconds(0), delay: queueService.refreshInterval) { task -> EventLoopFuture<Void> in
            return queueService.persistenceLayer.get(key: key, worker: container).flatMap { job in
                //No job found, go to the next iteration
                guard let job = job else { return container.future() }
                console.info("Dequeing Job", newLine: true)
                
                let futureJob = job.dequeue(context: jobContext, worker: container)
                return self.firstFutureToSucceed(future: futureJob, tries: job.maxRetryCount, on: container)
                    .flatMap { _ in
                        guard let jobString = job.stringValue(key: key) else { return container.future(error: Abort(.internalServerError)) }
                        return queueService.persistenceLayer.completed(key: key, jobString: jobString, worker: container)
                    }
                    .catchFlatMap { error in
                        console.error("Job error: \(error)", newLine: true)
                        return job.error(context: jobContext, error: error, worker: container).transform(to: ())
                }
            }
        }
        
        return promise.futureResult
    }
    
    private func firstFutureToSucceed<T>(future: Future<T>, tries: Int, on worker: Worker) -> Future<T> {
        return future.map { complete in
            return complete
        }.catchFlatMap { error in
            if tries == 0 {
                return worker.future(error: error)
            } else {
                return self.firstFutureToSucceed(future: future, tries: tries - 1, on: worker)
            }
        }
    }
}
