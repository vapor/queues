import Foundation
import NIO

public protocol AnyJob {
    static var jobName: String { get }
    func anyDequeue(context: JobContext, storage: JobStorage) -> EventLoopFuture<Void>
    func error(context: JobContext, error: Error) -> EventLoopFuture<Void>
}
