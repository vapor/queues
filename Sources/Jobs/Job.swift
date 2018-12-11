import NIO
import Foundation

public protocol Job: Codable {
    func dequeue(context: JobContext, worker: EventLoopGroup) -> EventLoopFuture<Void>
    func error(context: JobContext, error: Error, worker: EventLoopGroup) -> EventLoopFuture<Void>
}

extension Job {
    public func error(context: JobContext, error: Error, worker: EventLoopGroup) -> EventLoopFuture<Void> {
        return worker.future()
    }
    
    internal func stringValue(key: String, maxRetryCount: Int) -> String? {
        let jobData = JobData(key: key, data: self, maxRetryCount: maxRetryCount)
        guard let data = try? JSONEncoder().encode(jobData) else { return nil }
        guard let jobString = String(data: data, encoding: .utf8) else { return nil }
        return jobString
    }
}
