//
//  JobsWorkerTests.swift
//  Jobs
//
//  Created by Jimmy McDermott on 2019-08-05.
//

import XCTest
import NIO
import Logging
@testable import Jobs

final class JobsWorkerTests: XCTestCase {
    
    func testScheduledJob() throws {
        let el = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
        let expectation = XCTestExpectation(description: "Waits for scheduled job to be completed")
        var config = JobsConfiguration()
        
        guard let minute = Date().minute() else { XCTFail("Can't get date minute"); return }
        
        config.schedule(DailyCleanupScheduledJob(expectation: expectation))
            .hourly()
            .at(.init(minute + 1))
        
        let context = JobContext(eventLoop: el)
        let logger = Logger(label: "com.vapor.codes.jobs.tests")
        let worker = ScheduledJobsWorker(configuration: config,
                                         context: context,
                                         logger: logger,
                                         on: el)
        try worker.start()
        worker.shutdown()
        
        wait(for: [expectation], timeout: 61)
    }
}

struct DailyCleanupScheduledJob: ScheduledJob {
    let expectation: XCTestExpectation
    
    func run(context: JobContext) -> EvientLoopFuture<Void> {
        expectation.fulfill()
        return context.eventLoop.makeSucceededFuture(())
    }
}
