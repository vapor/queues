import Queues

struct MyAsyncJob: AsyncJob {
    let promise: EventLoopPromise<Void>

    struct Payload: Codable {
        var foo: String
    }

    func dequeue(_: QueueContext, _: Payload) async throws {
        self.promise.succeed()
    }
}
