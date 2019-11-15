//
//  JobMock.swift
//  Async
//
//  Created by Raul Riera on 2019-03-16.
//

import Jobs
import NIO

struct JobDataMock: Codable {}
struct JobDataOtherMock: Codable {}

struct JobMock<T: Codable>: Job {
    func dequeue(_ context: JobContext, _ data: T) -> EventLoopFuture<Void> {
        return context.eventLoop.future(())
    }
    
    func error(_ context: JobContext, _ error: Error, _ data: T) -> EventLoopFuture<Void> {
        return context.eventLoop.future(())
    }
}
