import Foundation
import Logging
import Vapor

public protocol JobsService {
    var logger: Logger { get }
    var driver: JobsDriver { get }
    var eventLoopPreference: JobsEventLoopPreference { get }
    var configuration: JobsConfiguration { get }
}

extension JobsService {
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
            return self.eventLoopPreference.delegate(
                for: self.driver.eventLoopGroup
            ).makeFailedFuture(error)
        }
        let jobStorage = JobStorage(
            key: self.configuration.persistenceKey,
            data: data,
            maxRetryCount: maxRetryCount,
            id: UUID().uuidString,
            jobName: JobData.jobName,
            delayUntil: delayUntil
        )
        self.logger.info("Dispatching job: \(jobData)")
        return self.driver.set(
            key: queue.makeKey(with: self.configuration.persistenceKey),
            job: jobStorage,
            eventLoop: self.eventLoopPreference
        ).map { _ in }
    }
    
    public func with(_ request: Request) -> JobsService {
        return RequestSpecificJobsService(request: request, service: self, configuration: self.configuration)
    }
}

struct ApplicationJobsService: JobsService {
    let configuration: JobsConfiguration
    let driver: JobsDriver
    let logger: Logger
    let eventLoopPreference: JobsEventLoopPreference
}

extension Request {
    public var jobs: JobsService {
        return self.application.make(JobsService.self).with(self)
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
    
    var eventLoopPreference: JobsEventLoopPreference {
        return .delegate(on: self.request.eventLoop)
    }
    
    public var configuration: JobsConfiguration
    
    init(request: Request, service: JobsService, configuration: JobsConfiguration) {
        self.request = request
        self.configuration = configuration
        self.service = service
    }
}
