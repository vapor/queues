import Vapor

public protocol Job: Codable {
    static func register()
    func dequeue(context: JobContext, worker: EventLoopGroup) throws -> EventLoopFuture<Void>
    func error(context: JobContext, error: Error, worker: EventLoopGroup) -> EventLoopFuture<Void>
}

fileprivate typealias JobTypeDecoder = (Decoder) throws -> Job
fileprivate var knownJobTypes: [String: JobTypeDecoder] = [:]

extension Job {
    func error(context: JobContext, error: Error, worker: EventLoopGroup) -> EventLoopFuture<Void> {
        return worker.future()
    }
}

extension Job where Self: Job {
    static func register() {
        knownJobTypes[String(describing: Self.self)] = Self.init(from: )
    }
    
    static func decode(from decoder: Decoder) throws -> Job {
        let jobType = String(describing: Self.self)
        guard let jobDecoder = knownJobTypes[jobType] else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown job type \(jobType)"))
        }
        
        return try jobDecoder(decoder)
    }
}
