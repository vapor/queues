import Vapor

public protocol Job: Codable {
    var maxRetryCount: Int { get }
    
    static func register()
    func dequeue(context: JobContext, worker: EventLoopGroup) throws -> EventLoopFuture<Void>
    func error(context: JobContext, error: Error, worker: EventLoopGroup) -> EventLoopFuture<Void>
}

extension Job {
    public func error(context: JobContext, error: Error, worker: EventLoopGroup) -> EventLoopFuture<Void> {
        return worker.future()
    }
}
