import Foundation

struct JobData: Codable {
    var key: String
    var data: Job
    
    init(key: String, data: Job) {
        self.key = key
        self.data = data
    }
    
    enum CodingKeys: String, CodingKey {
        case key, type, data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(String.self, forKey: .key)
        let typeString = try container.decode(String.self, forKey: .type)
        let jobDecoder = try container.superDecoder(forKey: .data)
        self.data = try JobsConfig.decode(jobType: typeString, from: jobDecoder)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.key, forKey: .key)
        let typeString = String(describing: type(of: self.data))
        try container.encode(typeString, forKey: .type)
        
        let superEncoder = container.superEncoder(forKey: .data)
        try self.data.encode(to: superEncoder)
    }
}
