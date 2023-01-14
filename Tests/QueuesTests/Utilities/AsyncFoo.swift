#if compiler(>=5.5) && canImport(_Concurrency)
import Queues

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
struct AsyncFoo: AsyncJob {
    typealias Payload = Data
    let promise: EventLoopPromise<Void>
    
    struct Data: Codable {
        var foo: String
    }
    
    func dequeue(_ context: QueueContext, _ payload: Payload) async throws {
        promise.succeed(())
        return
    }
}
#endif
