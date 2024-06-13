import Foundation

/// Holds information about the Job that is to be encoded to the persistence store.
public struct JobData: Codable, Sendable {
    /// The job data to be encoded.
    public let payload: [UInt8]
    
    /// The maxRetryCount for the `Job`.
    public let maxRetryCount: Int

    /// The number of attempts made to run the `Job`.
    public let attempts: Int?
    
    /// A date to execute this job after
    public let delayUntil: Date?
    
    /// The date this job was queued
    public let queuedAt: Date
    
    /// The name of the `Job`
    public let jobName: String
    
    /// Creates a new `JobStorage` holding object
    public init(
        payload: [UInt8],
        maxRetryCount: Int,
        jobName: String,
        delayUntil: Date?,
        queuedAt: Date,
        attempts: Int = 0
    ) {
        assert(maxRetryCount >= 0)
        assert(attempts >= 0)
        
        self.payload = payload
        self.maxRetryCount = maxRetryCount
        self.jobName = jobName
        self.delayUntil = delayUntil
        self.queuedAt = queuedAt
        self.attempts = attempts
    }
}

// N.B.: These methods are intended for internal use only.
extension JobData {
    /// The non-`nil` number of attempts made to run this job (how many times has it failed).
    /// This can also be treated as a "retry" count.
    ///
    /// Value | Meaning
    /// -|-
    /// 0 | The job has never run, or succeeded on its first attempt
    /// 1 | The job has failed once and is queued for its first retry
    /// 2... | The job has failed N times and is queued for its Nth retry
    var failureCount: Int {
        self.attempts ?? 0
    }
    
    /// The number of retries left iff the current (re)try fails.
    var remainingAttempts: Int {
        Swift.max(0, self.maxRetryCount - self.failureCount)
    }
    
    /// The current attempt number.
    ///
    /// Value|Meaning
    /// -|-
    /// 0|Not valid
    /// 1|The job has not failed thus far; this the first attempt.
    /// 2|The job has failed once; this is the second attempt.
    var currentAttempt: Int {
        self.failureCount + 1
    }
}
