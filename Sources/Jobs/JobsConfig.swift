import Foundation
import Vapor

public struct JobsConfig: Service {
    internal typealias JobTypeDecoder = (Decoder) throws -> Job
    
    //Any way to make this not static?
    static internal var storage: [String: JobTypeDecoder] = [:]
    
    public init() { }
    
    mutating public func add<J: Job>(_ job: J.Type) {
        JobsConfig.storage[String(describing: job)] = J.init(from: )
    }
    
    static func decode(jobType: String, from decoder: Decoder) throws -> Job {
        guard let jobDecoder = storage[jobType] else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown job type \(jobType)"))
        }
        
        return try jobDecoder(decoder)
    }
}
