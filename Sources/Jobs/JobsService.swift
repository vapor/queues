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
    public func dispatch<J>(
        _ job: J.Type,
        _ jobData: J.Data,
        maxRetryCount: Int = 0,
        queue: JobsQueue = .default,
        delayUntil: Date? = nil
    ) -> EventLoopFuture<Void>
        where J: Job
    {
        let data: Data
        do {
            data = try JSONEncoder().encode(jobData)
        } catch {
            return self.eventLoopPreference.delegate(
                for: self.driver.eventLoopGroup
            ).makeFailedFuture(error)
        }
        let jobID = UUID().uuidString
        let jobStorage = JobStorage(
            key: self.configuration.persistenceKey,
            data: data,
            maxRetryCount: maxRetryCount,
            id: jobID,
            jobName: J.jobName,
            delayUntil: delayUntil,
            queuedAt: Date()
        )
        return self.driver.set(
            key: queue.makeKey(with: self.configuration.persistenceKey),
            job: jobStorage,
            eventLoop: self.eventLoopPreference
        ).map { _ in
            self.logger.info("Dispatched queue job", metadata: [
                "job_id": .string("\(jobID)"),
                "queue": .string(queue.name)
            ])
        }
    }
}

