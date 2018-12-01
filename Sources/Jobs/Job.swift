import NIO

public protocol Job: Codable {
    func run(context: [String: Any]) throws -> EventLoopFuture<Void>
}
