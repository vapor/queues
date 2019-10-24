//
//  JobMock.swift
//  Async
//
//  Created by Raul Riera on 2019-03-16.
//

import Jobs
import NIO

struct JobDataMock: JobData {}
struct JobDataOtherMock: JobData {}

struct JobMock<T: JobData>: Job {
    func dequeue(_ context: JobContext, _ data: T) -> EventLoopFuture<Void> {
        return context.eventLoopGroup.next().makeSucceededFuture(())
    }
    
    func error(_ context: JobContext, _ error: Error, _ data: T) -> EventLoopFuture<Void> {
        return context.eventLoopGroup.next().makeSucceededFuture(())
    }
}
