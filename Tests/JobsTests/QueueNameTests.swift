//
//  QueueNameTests.swift
//  Async
//
//  Created by Raul Riera on 2019-03-16.
//

import XCTest
@testable import Jobs

final class QueueNameTests: XCTestCase {
    func testKeyIsGeneratedCorrectly() {
        let key = QueueName(name: "vapor").makeKey(with: "jobs")
        
        XCTAssertEqual(key, "jobs[vapor]")
    }
    
    static var allTests = [
        ("testKeyIsGeneratedCorrectly", testKeyIsGeneratedCorrectly),
        ]
}
