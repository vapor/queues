import NIO

public protocol Job: Codable {
    func dequeue(context: JobContext) throws -> EventLoopFuture<Void>
}
