//
//  JobsConfigTests.swift
//  Async
//
//  Created by Raul Riera on 2019-03-16.
//

import XCTest
import NIO
@testable import Jobs

final class JobsConfigTests: XCTestCase {
    func testAddingJobs() {
        var config = JobsConfig()
        config.add(JobMock<JobDataMock>())
        
        XCTAssertEqual(config.storage.count, 1)
        XCTAssertEqual(config.storage.first?.key, "JobDataMock")
    }
    
    func testAddingAlreadyRegistratedJobsAreIgnored() {
        var config = JobsConfig()
        config.add(JobMock<JobDataMock>())
        config.add(JobMock<JobDataMock>())
        
        XCTAssertEqual(config.storage.count, 1)
        XCTAssertNotNil(config.storage["JobDataMock"])
        
        config.add(JobMock<JobDataOtherMock>())
        
        XCTAssertEqual(config.storage.count, 2)
        XCTAssertNotNil(config.storage["JobDataOtherMock"])
    }
    
    static var allTests = [
        ("testAddingJobs", testAddingJobs),
        ("testAddingAlreadyRegistratedJobsAreIgnored", testAddingAlreadyRegistratedJobsAreIgnored)
    ]
}
