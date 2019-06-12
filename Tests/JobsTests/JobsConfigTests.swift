//
//  JobsConfigTests.swift
//  Async
//
//  Created by Raul Riera on 2019-03-16.
//

import XCTest
import NIO
@testable import Jobs

struct DailyCleanup: ScheduledJob {
    func run(context: JobContext) -> EventLoopFuture<Void> {
        return context.eventLoop.makeSucceededFuture(())
    }
}

final class JobsConfigTests: XCTestCase {
    func testAddingJobs() {
        var config = JobsConfiguration()
        config.add(JobMock<JobDataMock>())
        
        XCTAssertEqual(config.storage.count, 1)
        XCTAssertEqual(config.storage.first?.key, "JobDataMock")
    }
    
    func testAddingAlreadyRegistratedJobsAreIgnored() {
        var config = JobsConfiguration()
        config.add(JobMock<JobDataMock>())
        config.add(JobMock<JobDataMock>())
        
        XCTAssertEqual(config.storage.count, 1)
        XCTAssertNotNil(config.storage["JobDataMock"])
        
        config.add(JobMock<JobDataOtherMock>())
        
        XCTAssertEqual(config.storage.count, 2)
        XCTAssertNotNil(config.storage["JobDataOtherMock"])
    }
    
    func testScheduledJob() throws {
        var config = JobsConfiguration()
        try config.schedule(DailyCleanup()).daily().atHour(1).atMinute(1).atSecond(0)

        XCTAssertEqual(config.scheduledStorage.count, 1)
        XCTAssertEqual(config.scheduledStorage.first?.key, "DailyCleanup")
    }
    
    static var allTests = [
        ("testAddingJobs", testAddingJobs),
        ("testAddingAlreadyRegistratedJobsAreIgnored", testAddingAlreadyRegistratedJobsAreIgnored)
    ]
}
