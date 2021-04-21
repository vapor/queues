//
//  JobsEventLoopPreference.swift
//  
//
//  Created by Jimmy McDermott on 10/24/19.
//

import Foundation
import NIO

/// Determines which event loop the jobs worker uses while executing jobs.
public enum QueuesEventLoopPreference {
    /// The caller accepts connections and callbacks on any EventLoop.
    case indifferent

    /// The caller accepts connections on any event loop, but must be
    /// called back (delegated to) on the supplied EventLoop.
    /// If possible, the connection should also be on this EventLoop for
    /// improved performance.
    case delegate(on: EventLoop)

    /// Returns the delegate EventLoop given an EventLoopGroup.
    public func delegate(for eventLoopGroup: EventLoopGroup) -> EventLoop {
        switch self {
        case .indifferent:
            return eventLoopGroup.next()
        case .delegate(let eventLoop):
            return eventLoop
        }
    }
}
