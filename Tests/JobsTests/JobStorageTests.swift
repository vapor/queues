//
//  JobStorageTests.swift
//  Async
//
//  Created by Raul Riera on 2019-03-16.
//

import XCTest
@testable import Jobs

final class JobStorageTests: XCTestCase {
    func testStringRepresentationIsValidJSON() {
        let jobStorage = JobData(key: "vapor",
                                    data: Data(),
                                    maxRetryCount: 1,
                                    id: "identifier",
                                    jobName: "jobs",
                                    delayUntil: nil,
                                    queuedAt: Date())
        
        let stringRepresentation = jobStorage.stringValue()
        
        if let data = stringRepresentation?.data(using: String.Encoding.utf8), let jobStorageRestored = try? JSONDecoder().decode(JobData.self, from: data) {
            XCTAssertEqual(jobStorage.key, jobStorageRestored.key)
            XCTAssertEqual(jobStorage.data, jobStorageRestored.data)
            XCTAssertEqual(jobStorage.maxRetryCount, jobStorageRestored.maxRetryCount)
            XCTAssertEqual(jobStorage.id, jobStorageRestored.id)
            XCTAssertEqual(jobStorage.jobName, jobStorageRestored.jobName)
            XCTAssertEqual(jobStorage.delayUntil, nil)
        } else {
            XCTFail("There was a problem restoring JobStorage")
        }
    }
}
