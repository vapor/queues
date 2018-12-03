import Vapor

public protocol Job: Codable {
    var maxRetryCount: Int { get }
    
    static func register()
    func dequeue(context: JobContext, worker: EventLoopGroup) throws -> EventLoopFuture<Void>
    func error(context: JobContext, error: Error, worker: EventLoopGroup) -> EventLoopFuture<Void>
}

internal typealias JobTypeDecoder = (Decoder) throws -> Job
internal var knownJobTypes: [String: JobTypeDecoder] = [:]

extension Job {    
    func error(context: JobContext, error: Error, worker: EventLoopGroup) -> EventLoopFuture<Void> {
        return worker.future()
    }
}

//TODO: - Clean these methods up and add a helper config type
extension Job where Self: Job {
    static func register() {
        knownJobTypes[String(describing: Self.self)] = Self.init(from: )
    }
}
