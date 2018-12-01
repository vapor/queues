import Foundation

struct JobData<T> where T: Job {
    let job: T
    let configuration: QueueConfiguration
}

extension JobData: Codable { }
