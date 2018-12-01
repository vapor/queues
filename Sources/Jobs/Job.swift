import NIO

public protocol Job: Codable {
    func dequeue(context: [String: Any]) throws -> EventLoopFuture<Void>
}
