import Foundation

public struct QueueConfiguration: Codable {
    let retryAttempts: Int
    let runOn: Date?
    let startOn: Date?
    let interval: Double?
    let stopOn: Date?
    let stopAfter: Int?
    
    public static func oneOff(retryAttempts: Int = 0) -> QueueConfiguration {
        return QueueConfiguration(retryAttempts: retryAttempts,
                                  runOn: nil,
                                  startOn: nil,
                                  interval: nil,
                                  stopOn: nil,
                                  stopAfter: nil)
    }
    
    public static func scheduled(runOn: Date, retryAttempts: Int = 0) -> QueueConfiguration {
        return QueueConfiguration(retryAttempts: retryAttempts,
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
                                 retryAttempts: Int = 0) -> QueueConfiguration
    {
        guard stopOn != nil || stopAfter != nil else { fatalError("Must specify either a stopOn date or a number of runs to stop after.") }
        return QueueConfiguration(retryAttempts: retryAttempts,
                                  runOn: nil,
                                  startOn: startOn,
                                  interval: interval,
                                  stopOn: stopOn,
                                  stopAfter: stopAfter)
    }
}
