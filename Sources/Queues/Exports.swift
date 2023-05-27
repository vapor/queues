#if swift(>=5.8)

@_documentation(visibility: internal) @_exported import struct Foundation.Date
@_documentation(visibility: internal) @_exported import struct Logging.Logger
@_documentation(visibility: internal) @_exported import class NIOCore.EventLoopFuture
@_documentation(visibility: internal) @_exported import struct NIOCore.EventLoopPromise
@_documentation(visibility: internal) @_exported import protocol NIOCore.EventLoop
@_documentation(visibility: internal) @_exported import struct NIOCore.TimeAmount

#else

@_exported import struct Foundation.Date
@_exported import struct Logging.Logger
@_exported import class NIOCore.EventLoopFuture
@_exported import struct NIOCore.EventLoopPromise
@_exported import protocol NIOCore.EventLoop
@_exported import struct NIOCore.TimeAmount

#endif
