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

        // hourly
        config.schedule(Cleanup())
            .hourly()
            .at(30)

    }
}

final class Cleanup: ScheduledJob {
    func run(context: JobContext) -> EventLoopFuture<Void> {
        return context.eventLoop.makeSucceededFuture(())
    }
}
