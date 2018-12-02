import Vapor

public protocol Job: Codable {
    static func register()
    func dispatch(context: JobContext, worker: EventLoopGroup) throws -> EventLoopFuture<Void>
}

fileprivate typealias JobTypeDecoder = (Decoder) throws -> Job
fileprivate var knownJobTypes: [String: JobTypeDecoder] = [:]

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
