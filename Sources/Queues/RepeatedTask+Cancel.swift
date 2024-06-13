import NIOCore
import Logging

extension RepeatedTask {
    func syncCancel(on eventLoop: any EventLoop) {
        do {
            let promise = eventLoop.makePromise(of: Void.self)
            self.cancel(promise: promise)
            try promise.futureResult.wait()
        } catch {
            Logger(label: "codes.vapor.queues.repeatedtask").debug("Failed cancelling repeated task", metadata: ["error": "\(error)"])
        }
    }
    
    func asyncCancel(on eventLoop: any EventLoop) async {
        do {
            let promise = eventLoop.makePromise(of: Void.self)
            self.cancel(promise: promise)
            try await promise.futureResult.get()
        } catch {
            Logger(label: "codes.vapor.queues.repeatedtask").debug("Failed cancelling repeated task", metadata: ["error": "\(error)"])
        }
    }
}
