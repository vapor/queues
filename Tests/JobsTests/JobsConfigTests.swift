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
        return context.eventLoop.future(())
    }
}

final class JobsConfigTests: XCTestCase {
    func testAddingJobs() {
        var config = JobsConfiguration()
        config.add(JobMock<JobDataMock>())
        
        XCTAssertEqual(config.storage.count, 1)
        XCTAssertEqual(config.storage.first?.key, "JobMock<JobDataMock>")
    }
    
    func testAddingAlreadyRegistratedJobsAreIgnored() {
        var config = JobsConfiguration()
        config.add(JobMock<JobDataMock>())
        config.add(JobMock<JobDataMock>())
        
        XCTAssertEqual(config.storage.count, 1)
        XCTAssertNotNil(config.storage["JobMock<JobDataMock>"])
        
        config.add(JobMock<JobDataOtherMock>())
        
        XCTAssertEqual(config.storage.count, 2)
        XCTAssertNotNil(config.storage["JobMock<JobDataOtherMock>"])
    }
    
    // https://github.com/vapor/jobs/issues/38
    func testAddingJobsWithTheSameDataType() {
        struct JobOne: Job {
            func dequeue(_ context: JobContext, _ data: [String : String]) -> EventLoopFuture<Void> {
                fatalError()
            }
            
            typealias Data = [String: String]
        }
        
        struct JobTwo: Job {
            func dequeue(_ context: JobContext, _ data: [String : String]) -> EventLoopFuture<Void> {
                fatalError()
            }
            
            typealias Data = [String: String]
        }
        
        var config = JobsConfiguration()
        config.add(JobOne())
        config.add(JobTwo())
        
        XCTAssertEqual(config.storage.count, 2)
        XCTAssertNotNil(config.storage["JobOne"])
        XCTAssertNotNil(config.storage["JobTwo"])
    }
    
    func testScheduledJob() throws {
        var config = JobsConfiguration()
        config.schedule(DailyCleanup())
            .daily()
            .at("1:01am")

        XCTAssertEqual(config.scheduledStorage.count, 1)
    }
}
