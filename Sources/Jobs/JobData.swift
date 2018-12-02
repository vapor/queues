import Foundation

struct JobData<T>: Codable where T: Job {
    let job: T
    let maxRetryCount: Int?
}
