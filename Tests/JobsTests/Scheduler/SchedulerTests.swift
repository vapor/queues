@testable import Jobs
import XCTest

final class SchedulerTests: XCTestCase {

    func testConfiguration() throws {
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

    func testScheduleEvaluationYearly() throws {
        var config = JobsConfiguration()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        // yearly
        config.schedule(Cleanup())
            .yearly()
            .in(.may)
            .on(23)
            .at(.noon)

        // Fri, Jan 1, 2019 00:00:00
        let date1 = dateFormatter.date(from: "2019-01-01T00:00:00")!

        // May 31, 2019 12:00:00
        let date2 = dateFormatter.date(from: "2019-05-23T12:00:00")!

        let nextDate = try config.scheduledStorage.first?.scheduler.resolveNextDateThatSatisifiesSchedule(date: date1)
        XCTAssertEqual(nextDate, date2)
    }

    func testScheduleEvaluationMonthly() throws {
        var config = JobsConfiguration()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        // monthly
        config.schedule(Cleanup())
            .monthly()
            .on(15)
            .at(.midnight)

        // Fri, Jan 1, 2019 00:00:00
        let date1 = dateFormatter.date(from: "2019-01-01T00:00:00")!

        // Jan 15, 2019 24:00:00
        let date2 = dateFormatter.date(from: "2019-01-15T00:00:00")!

        let nextDate = try config.scheduledStorage.first?.scheduler.resolveNextDateThatSatisifiesSchedule(date: date1)
        XCTAssertEqual(nextDate, date2)
    }

    func testScheduleEvaluationWeekly() throws {
        var config = JobsConfiguration()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        // weekly
        config.schedule(Cleanup())
            .weekly()
            .on(.monday)
            .at("3:13am")

        // Fri, Jan 1, 2019 00:00:00
        let date1 = dateFormatter.date(from: "2019-01-01T00:00:00")!

        // Mon Jan 7, 2019 3:13:00
        let date2 = dateFormatter.date(from: "2019-01-07T3:13:00")!

        let nextDate = try config.scheduledStorage.first?.scheduler.resolveNextDateThatSatisifiesSchedule(date: date1)
        XCTAssertEqual(nextDate, date2)
    }

    func testScheduleEvaluationDaily() throws {
        var config = JobsConfiguration()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        // daily 1
        config.schedule(Cleanup())
            .daily()
            .at("5:23pm")

        // Fri, Jan 1, 2019 00:00:00
        let date1 = dateFormatter.date(from: "2019-01-01T00:00:00")!

        // Jan 1, 2019 17:23:00
        let date2 = dateFormatter.date(from: "2019-01-01T17:23:00")!

        let nextDate = try config.scheduledStorage.first?.scheduler.resolveNextDateThatSatisifiesSchedule(date: date1)
        XCTAssertEqual(nextDate, date2)

        // daily 2
        config.schedule(Cleanup())
            .daily()
            .at(5, 23, .pm)

        // Fri, Jan 1, 2019 00:00:00
        let date3 = dateFormatter.date(from: "2019-01-01T00:00:00")!

        // Jan 1, 2019 17:23:00
        let date4 = dateFormatter.date(from: "2019-01-01T17:23:00")!

        let nextDate2 = try config.scheduledStorage[1].scheduler.resolveNextDateThatSatisifiesSchedule(date: date3)
        XCTAssertEqual(nextDate2, date4)

        // daily 3
        config.schedule(Cleanup())
            .daily()
            .at(17, 23)

        // Fri, Jan 1, 2019 00:00:00
        let date5 = dateFormatter.date(from: "2019-01-01T00:00:00")!

        // Jan 1, 2019 17:23:00
        let date6 = dateFormatter.date(from: "2019-01-01T17:23:00")!

        let nextDate3 = try config.scheduledStorage[2].scheduler.resolveNextDateThatSatisifiesSchedule(date: date5)
        XCTAssertEqual(nextDate3, date6)
    }

    func testScheduleEvaluationHourly() throws {
        var config = JobsConfiguration()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        // hourly
        config.schedule(Cleanup())
            .hourly()
            .at(30)

        // Fri, Jan 1, 2019 00:00:00
        let date1 = dateFormatter.date(from: "2019-01-01T00:00:00")!

        // Jan 1, 2019 0:30:00
        let date2 = dateFormatter.date(from: "2019-01-01T0:30:00")!

        let nextDate = try config.scheduledStorage.first?.scheduler.resolveNextDateThatSatisifiesSchedule(date: date1)
        XCTAssertEqual(nextDate, date2)
    }
    
    func testScheduleEvaluationEveryMinute() throws {
        var config = JobsConfiguration()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        // hourly
        config.schedule(Cleanup())
            .everyMinute()
            .at(30)
        
        // Fri, Jan 1, 2019 00:00:00
        let date1 = dateFormatter.date(from: "2019-01-01T00:00:00")!
        
        // Jan 1, 2019 0:00:30
        let date2 = dateFormatter.date(from: "2019-01-01T0:00:30")!
        
        let nextDate = try config.scheduledStorage.first?.scheduler.resolveNextDateThatSatisifiesSchedule(date: date1)
        XCTAssertEqual(nextDate, date2)
    }
}

final class Cleanup: ScheduledJob {
    func run(context: JobContext) -> EventLoopFuture<Void> {
        return context.eventLoop.future(())
    }
}
