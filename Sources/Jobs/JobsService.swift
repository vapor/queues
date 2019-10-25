import Foundation
import Logging
import Vapor

public protocol JobsService {
    var driver: JobsDriver { get }
    var preference: JobsEventLoopPreference { get }
    var configuration: JobsConfiguration { get }
    
    /// Dispatches a job to the queue for future execution
    ///
    /// - Parameters:
    ///   - jobData: The `JobData` to dispatch to the queue
    ///   - maxRetryCount: The number of retries to attempt upon error before calling `Job`.`error()`
    ///   - queue: The queue to run this job on
    ///   - delay: A date to execute the job after
    /// - Returns: A future `Void` value used to signify completion
    func dispatch<JobData>(
        _ jobData: JobData,
        maxRetryCount: Int,
        queue: JobsQueue,
        delayUntil: Date?
    ) -> EventLoopFuture<Void>
        where JobData: Jobs.JobData
}

extension JobsService {
    public var eventLoop: EventLoop {
        switch self.preference {
        case .indifferent:
            return self.driver.eventLoop
        case .delegate(let eventLoop):
            return eventLoop
        }
    }
    
    public func dispatch<JobData>(
           _ jobData: JobData,
           maxRetryCount: Int = 0,
           queue: JobsQueue = .default,
           delayUntil: Date? = nil
       ) -> EventLoopFuture<Void>
           where JobData: Jobs.JobData
       {
           let data: Data
           do {
               data = try JSONEncoder().encode(jobData)
           } catch {
               return self.driver.eventLoop.makeFailedFuture(error)
           }
           let jobStorage = JobStorage(
               key: self.configuration.persistenceKey,
               data: data,
               maxRetryCount: maxRetryCount,
               id: UUID().uuidString,
               jobName: JobData.jobName,
               delayUntil: delayUntil,
               queuedAt: Date()
           )
           return self.driver.set(
               key: queue.makeKey(with: self.configuration.persistenceKey),
               jobStorage: jobStorage
           ).map { _ in }
       }
    
    public func with(_ request: Request) -> JobsService {
        return RequestSpecificJobsService(request: request, service: self, configuration: self.configuration)
    }
}

private struct RequestSpecificJobsService: JobsService {
    public let request: Request
    public let service: JobsService
    
    var driver: JobsDriver {
        return self.service.driver
    }
    
    var logger: Logger {
        return self.request.logger
    }
    
    var preference: JobsEventLoopPreference {
        return .delegate(on: self.request.eventLoop)
    }
    
    public var configuration: JobsConfiguration
    
    init(request: Request, service: JobsService, configuration: JobsConfiguration) {
        self.request = request
        self.configuration = configuration
        self.service = service
    }
}

public struct BasicJobsService: JobsService {
    public var preference: JobsEventLoopPreference
    var logger: Logger {
        return Logger(label: "com.vapor.codes.jobs")
    }
    
    public var configuration: JobsConfiguration
    public let driver: JobsDriver
    
    internal init(
        configuration: JobsConfiguration,
        driver: JobsDriver,
        preference: JobsEventLoopPreference
    ) {
        self.configuration = configuration
        self.driver = driver
        self.preference = preference
    }
}
