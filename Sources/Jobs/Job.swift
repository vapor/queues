import Vapor

public protocol Job: Codable {
    static func register<T: Job>(_ jobType: T.Type)
    func dispatch(context: JobContext) throws -> EventLoopFuture<Void>
}

fileprivate typealias JobTypeDecoder = (Decoder) throws -> Job
fileprivate var knownJobTypes: [String: JobTypeDecoder] = [:]

extension Job {
    static func register<T: Job>(_ jobType: T.Type = T.self) {
        knownJobTypes[String(describing: T.self)] = T.init(from: )
    }
    
    static func decode(jobType: String, from decoder: Decoder) throws -> Job {
        guard let jobDecoder = knownJobTypes[jobType] else { throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown job type \(jobType)")) }
        return try jobDecoder(decoder)
    }
}
