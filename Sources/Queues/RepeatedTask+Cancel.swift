import NIOCore

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
    
    func asyncCancel(on eventLoop: EventLoop) async {
        do {
            let promise = eventLoop.makePromise(of: Void.self)
            self.cancel(promise: promise)
            try await promise.futureResult.get()
        } catch {
            print("failed cancelling repeated task \(error)")
        }
    }
}
