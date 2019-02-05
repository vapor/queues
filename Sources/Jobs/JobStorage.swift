import Foundation

/// Holds information about the Job that is to be encoded to the persistence store.
public struct JobStorage: Codable {
    
    /// The persistence key for the backing store.
    var key: String
    
    /// The `JobData` to be encoded.
    var data: Data
    
    /// The maxRetryCount for the `Job`.
    var maxRetryCount: Int
    
    /// A unique ID for the job
    var id: String
    
    /// The name of the `Job`
    var jobName: String
    
    /// Creates a new `JobStorage` holding object
    public init(key: String, data: Data, maxRetryCount: Int, id: String, jobName: String) {
        self.key = key
        self.data = data
        self.maxRetryCount = maxRetryCount
        self.id = id
        self.jobName = jobName
    }
    
    /// Returns a string representation of the JobStorage object
    ///
    /// - Parameters:
    ///   - key: See `JobStorage`.`key`
    ///   - maxRetryCount: See `JobStorage`.`maxRetryCount`
    ///   - id: See `JobStorage`.`id`
    /// - Returns: The string representation
    public func stringValue(key: String, maxRetryCount: Int, id: String) -> String? {
        guard let jobStorageData = try? JSONEncoder().encode(self) else { return nil }
        guard let jobString = String(data: jobStorageData, encoding: .utf8) else { return nil }
        return jobString
    }
}
