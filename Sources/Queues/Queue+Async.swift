import Vapor
import NIOCore

#if compiler(>=5.5) && canImport(_Concurrency)
extension Queue {
    /// Dispatch a job into the queue for processing
    /// - Parameters:
    ///   - job: The Job type
    ///   - payload: The payload data to be dispatched
    ///   - maxRetryCount: Number of times to retry this job on failure
    ///   - delayUntil: Delay the processing of this job until a certain date
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    public func dispatch<J>(
        _ job: J.Type,
        _ payload: J.Payload,
        maxRetryCount: Int = 0,
        delayUntil: Date? = nil,
        id: JobIdentifier = JobIdentifier()
    ) async throws where J: Job {
        try await self.dispatch(job, payload, maxRetryCount: maxRetryCount, delayUntil: delayUntil, id: id).get()
    }
}
#endif
