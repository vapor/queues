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

extension Job where Self: Job {
    static func register() {
        knownJobTypes[String(describing: Self.self)] = Self.init(from: )
    }
}

func decode(_ jobType: Any.Type, from decoder: Decoder) throws -> Job {
    let jobTypeString = String(describing: jobType)
    guard let jobDecoder = knownJobTypes[jobTypeString] else {
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown job type \(jobTypeString)"))
    }
    
    return try jobDecoder(decoder)
}
