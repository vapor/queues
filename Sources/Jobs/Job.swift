import NIO

public protocol Job: Codable {
    var maxRetryCount: Int? { get set }
    func dequeue(context: JobContext) throws -> EventLoopFuture<Void>
}
