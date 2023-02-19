import class NIO.RepeatedTask

extension RepeatedTask {
    func syncCancel(on eventLoop: EventLoop) {
        do {
            let promise = eventLoop.makePromise(of: Void.self)
            self.cancel(promise: promise)
            try promise.futureResult.wait()
        } catch {
            print("failed cancelling repeated task \(error)")
        }
    }
}