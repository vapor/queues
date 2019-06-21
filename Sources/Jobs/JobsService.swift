import Foundation

/// A `Service` used to dispatch `Jobs`
public struct JobsService {
    internal let configuration: JobsConfiguration
    internal let driver: JobsDriver

    internal init(
        configuration: JobsConfiguration,
        driver: JobsDriver
    ) {
        self.configuration = configuration
        self.driver = driver
    }

    /// Dispatches a job to the queue for future execution
    ///
    /// - Parameters:
    ///   - jobData: The `JobData` to dispatch to the queue
    ///   - maxRetryCount: The number of retries to attempt upon error before calling `Job`.`error()`
    ///   - queue: The queue to run this job on
    ///   - delay: A date to execute the job after
    /// - Returns: A future `Void` value used to signify completion
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
            delayUntil: delayUntil
        )
        return self.driver.set(
            key: queue.makeKey(with: self.configuration.persistenceKey),
            jobStorage: jobStorage
        ).map { _ in }
    }
}
