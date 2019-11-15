import Foundation
import Vapor

public protocol JobsService: Service {
    var driver: JobsDriver { get }
    var eventLoopPreference: JobsEventLoopPreference { get }
    var configuration: JobsConfiguration { get }
}

extension JobsService {
    public func dispatch<Job>(
        _ job: Job.Type,
        _ jobData: Job.Data,
        maxRetryCount: Int = 0,
        queue: JobsQueue = .default,
        delayUntil: Date? = nil
    ) -> EventLoopFuture<Void>
        where Job: Jobs.Job
    {
        let data: Data
        do {
            data = try JSONEncoder().encode(jobData)
        } catch {
            return self.eventLoopPreference.delegate(
                for: self.driver.eventLoopGroup
            ).future(error: error)
        }
        let jobID = UUID().uuidString
        let jobStorage = JobStorage(
            key: self.configuration.persistenceKey,
            data: data,
            maxRetryCount: maxRetryCount,
            id: jobID,
            jobName: Job.jobName,
            delayUntil: delayUntil,
            queuedAt: Date()
        )
        return self.driver.set(
            key: queue.makeKey(with: self.configuration.persistenceKey),
            job: jobStorage,
            eventLoop: self.eventLoopPreference
        ).map { _ in
            print("INFO: Dispatched queue job\n\tjob_id: \(jobID)\n\tqueue: \(queue.name)")
        }
    }
    
    public func with(_ request: Request) -> JobsService {
        return RequestSpecificJobsService(request: request, service: self, configuration: self.configuration)
    }
}

struct ApplicationJobsService: JobsService {
    let configuration: JobsConfiguration
    let driver: JobsDriver
    let eventLoopPreference: JobsEventLoopPreference
}

extension Request {
    public var jobs: JobsService {
        return try! self.make(JobsService.self).with(self)
    }
}


private struct RequestSpecificJobsService: JobsService {
    public let request: Request
    public let service: JobsService
    
    var driver: JobsDriver {
        return self.service.driver
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
