import XCTest
import Vapor
import Queues

public func XCTAssertDispatched<J: Job>(_ job: J.Type, on queue: QueueName = .default, app: Application, file: StaticString = #file, line: UInt = #line) {
    // maybe loop through them if multiple was queued
    do {
        guard
            let jobID = try app.queues.queue(queue).pop().wait() else {
                XCTFail("Job \(job) was not found in queue", file: file, line: line)
            return
        }
        
        let data = try app.queues.queue(queue).get(jobID).wait()
        XCTAssertEqual(data.jobName, job.name)
    } catch {
        XCTFail("\(error)", file: file, line: line)
    }
}
