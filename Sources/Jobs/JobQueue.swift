import Foundation
import Vapor
import NIO

/// A `Service` used to dispatch `Jobs`
public struct JobQueue {
    /// A specific queue that jobs are run on.
    public struct Name {
        /// The default queue that jobs are run on
        public static let `default` = Name(string: "default")

        /// The name of the queue
        public let string: String

        /// Creates a new `QueueType`
        ///
        /// - Parameter name: The name of the `QueueType`
        public init(string: String) {
            self.string = string
        }

        /// Makes the name of the queue
        ///
        /// - Parameter persistanceKey: The base persistence key
        /// - Returns: A string of the queue's fully qualified name
        public func makeKey(with persistanceKey: String) -> String {
            return persistanceKey + "[\(self.string)]"
        }
    }

    let configuration: JobsConfiguration
    let driver: JobsDriver

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
    ///   - data: The `JobData` to dispatch to the queue
    ///   - maxRetryCount: The number of retries to attempt upon error before calling `Job`.`error()`
    ///   - queue: The queue to run this job on
    ///   - delay: A date to execute the job after
    /// - Returns: A future `Void` value used to signify completion
    public func dispatch<Data>(
        _ data: Data,
        maxRetryCount: Int = 0,
        queue: Name = .default,
        delayUntil: Date? = nil
    ) throws -> EventLoopFuture<Void>
        where Data: JobData
    {
        let data = try JSONEncoder().encode(data)
        let jobStorage = JobStorage(
            key: self.configuration.persistenceKey,
            data: data,
            maxRetryCount: maxRetryCount,
            id: UUID().uuidString,
            jobName: Data.jobName,
            delayUntil: delayUntil
        )
        return self.driver.set(
            key: queue.makeKey(with: self.configuration.persistenceKey),
            jobStorage: jobStorage
        ).map { _ in }
    }
}
