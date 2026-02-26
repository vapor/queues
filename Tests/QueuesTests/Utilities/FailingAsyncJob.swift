import Queues

struct FailingAsyncJob: AsyncJob {
    let promise: EventLoopPromise<Void>

    struct Payload: Codable {
        var foo: String
    }

    func dequeue(_: QueueContext, _: Payload) async throws {
        let failure = Failure()
        self.promise.fail(failure)
        throw failure
    }
}
