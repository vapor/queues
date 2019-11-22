@_exported import struct Foundation.Date
@_exported import struct Logging.Logger
@_exported import class NIO.EventLoopFuture
@_exported import struct NIO.EventLoopPromise
@_exported import protocol NIO.EventLoop
@_exported import struct NIO.TimeAmount

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
