//
//  JobsWorkerTests.swift
//  Jobs
//
//  Created by Jimmy McDermott on 2019-08-05.
//

import XCTest
import NIO
@testable import Jobs

final class JobsWorkerTests: XCTestCase {

    func testScheduledJob() throws {
        let elg = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let expectation = XCTestExpectation(description: "Waits for scheduled job to be completed")
        var config = JobsConfiguration()

        guard let second = Date().second() else { XCTFail("Can't get date second"); return }

        config.schedule(DailyCleanupScheduledJob(expectation: expectation))
            .everyMinute()
            .at(.init(second + 2))

        let worker = ScheduledJobsWorker(
            configuration: config,
            on: elg.next()
        )
        try worker.start()

        XCTAssertEqual(worker.scheduledJobs.count, 1)
        wait(for: [expectation], timeout: 3)

        try elg.next().scheduleTask(in: .seconds(1)) { () -> Void in
            // Test that job was rescheduled
            XCTAssertEqual(worker.scheduledJobs.count, 2)
            worker.shutdown()
        }.futureResult.wait()
    }

    func testScheduledJobAt() throws {
        let elg = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let expectation = XCTestExpectation(description: "Waits for scheduled job to be completed")
        var config = JobsConfiguration()

        config.schedule(DailyCleanupScheduledJob(expectation: expectation)).at(Date().addingTimeInterval(5))

        let worker = ScheduledJobsWorker(
            configuration: config,
            on: elg.next()
        )
        try worker.start()

        XCTAssertEqual(worker.scheduledJobs.count, 1)
        wait(for: [expectation], timeout: 6)

        try elg.next().scheduleTask(in: .seconds(1)) { () -> Void in
            // Test that job was not rescheduled
            XCTAssertEqual(worker.scheduledJobs.count, 0)
            worker.shutdown()
        }.futureResult.wait()
    }
}

struct DailyCleanupScheduledJob: ScheduledJob {
    let expectation: XCTestExpectation

    func run(context: JobContext) -> EventLoopFuture<Void> {
        expectation.fulfill()
        return context.eventLoop.future(())
    }
}
