import Foundation

public struct JobData: Codable {
    var key: String
    var data: Job
    var maxRetryCount: Int
    
    init(key: String, data: Job, maxRetryCount: Int) {
        self.key = key
        self.data = data
        self.maxRetryCount = maxRetryCount
    }
    
    enum CodingKeys: String, CodingKey {
        case key, type, data, maxRetryCount
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(String.self, forKey: .key)
        self.maxRetryCount = try container.decode(Int.self, forKey: .maxRetryCount)
        let typeString = try container.decode(String.self, forKey: .type)
        let jobDecoder = try container.superDecoder(forKey: .data)
        self.data = try JobsConfig.decode(jobType: typeString, from: jobDecoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.key, forKey: .key)
        try container.encode(self.maxRetryCount, forKey: .maxRetryCount)
        let typeString = String(describing: type(of: self.data))
        try container.encode(typeString, forKey: .type)
        
        let superEncoder = container.superEncoder(forKey: .data)
        try self.data.encode(to: superEncoder)
    }
}
