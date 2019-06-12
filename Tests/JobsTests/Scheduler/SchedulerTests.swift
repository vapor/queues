@testable import Jobs
import XCTest

final class SchedulerTests: XCTestCase {
    func testAll() throws {
        var config = JobsConfiguration()
        
        // yearly
        config.schedule(Cleanup())
            .yearly()
            .in(.may)
            .on(23)
            .at(.noon)

        // monthly
        config.schedule(Cleanup())
            .monthly()
            .on(15)
            .at(.midnight)
        
        // weekly
        config.schedule(Cleanup())
            .weekly()
            .on(.monday)
            .at("3:13am")

        // daily
        config.schedule(Cleanup())
            .daily()
            .at("5:23pm")
        
        // daily 2
        config.schedule(Cleanup())
            .daily()
            .at(5, 23, .pm)
        
        // daily 3
        config.schedule(Cleanup())
            .daily()
            .at(17, 23)

        // hourly
        config.schedule(Cleanup())
            .hourly()
            .at(30)

        XCTAssertEqual(config.scheduledStorage.count, 7)
    }
}

final class Cleanup: ScheduledJob {
    func run(context: JobContext) -> EventLoopFuture<Void> {
        return context.eventLoop.makeSucceededFuture(())
    }
}
