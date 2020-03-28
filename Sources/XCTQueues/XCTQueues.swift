import XCTest
import Vapor
import Queues

public func XCTAssertDispatched<J: Job>(_ job: J.Type, on queue: QueueName = .default, app: Application, file: StaticString = #file, line: UInt = #line) {
    var popped = [JobIdentifier]()
    defer {
        try! popped.map {
            app.queues.queue(queue).push($0)
        }.flatten(on: app.eventLoopGroup.next()).wait()
    }
    do {
        var jobFound = false
        while !jobFound {
            guard let jobID = try app.queues.queue(queue).pop().wait() else {
                XCTFail("Job \(job) was not found in queue", file: file, line: line)
                break
            }
            popped.append(jobID)
            let data = try app.queues.queue(queue).get(jobID).wait()
            if data.jobName == job.name {
                jobFound = true
                return
            }
        }
    } catch {
        XCTFail("\(error)", file: file, line: line)
    }
}
