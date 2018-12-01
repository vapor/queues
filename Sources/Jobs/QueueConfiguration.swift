import Foundation

public struct QueueConfiguration: Codable {
    let retryOnError: Bool
    let retryAttempts: Int?
    let runOn: Date?
    let startOn: Date?
    let interval: Double?
    let stopOn: Date?
    let stopAfter: Int?
    
    public static func oneOff(retryOnError: Bool, retryAttempts: Int?) -> QueueConfiguration {
        return QueueConfiguration(retryOnError: retryOnError,
                                  retryAttempts: retryAttempts,
                                  runOn: nil,
                                  startOn: nil,
                                  interval: nil,
                                  stopOn: nil,
                                  stopAfter: nil)
    }
    
    public static func scheduled(runOn: Date, retryOnError: Bool, retryAttempts: Int?) -> QueueConfiguration {
        return QueueConfiguration(retryOnError: retryOnError,
                                  retryAttempts: retryAttempts,
                                  runOn: runOn,
                                  startOn: nil,
                                  interval: nil,
                                  stopOn: nil,
                                  stopAfter: nil)
    }
    
    public static func repeating(startOn: Date,
                                 interval: Double,
                                 stopOn: Date?,
                                 stopAfter: Int?,
                                 retryOnError: Bool,
                                 retryAttempts: Int?) -> QueueConfiguration
    {
        return QueueConfiguration(retryOnError: retryOnError,
                                  retryAttempts: retryAttempts,
                                  runOn: nil,
                                  startOn: startOn,
                                  interval: interval,
                                  stopOn: stopOn,
                                  stopAfter: stopAfter)
    }
}
