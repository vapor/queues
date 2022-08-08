import Queues
import XCTest

final class ScheduleBuilderTests: XCTestCase {
    func testHourlyBuilder() throws {
        let builder = ScheduleBuilder()
        builder.hourly().at(30)
        // same time
        XCTAssertEqual(
            builder.nextDate(current: Date(hour: 5, minute: 30)),
            // plus one hour
            Date(hour: 6, minute: 30)
        )
        // just before
        XCTAssertEqual(
            builder.nextDate(current: Date(hour: 5, minute: 29)),
            // plus one minute
            Date(hour: 5, minute: 30)
        )
        // just after
        XCTAssertEqual(
            builder.nextDate(current: Date(hour: 5, minute: 31)),
            // plus one hour
            Date(hour: 6, minute: 30)
        )
    }
    
    func testDailyBuilder() throws {
        let builder = ScheduleBuilder()
        builder.daily().at("5:23am")
        // same time
        XCTAssertEqual(
            builder.nextDate(current: Date(day: 1, hour: 5, minute: 23)),
            // plus one day
            Date(day: 2, hour: 5, minute: 23)
        )
        // just before
        XCTAssertEqual(
            builder.nextDate(current: Date(day: 1, hour: 5, minute: 22)),
            // plus one minute
            Date(day: 1, hour: 5, minute: 23)
        )
        // just after
        XCTAssertEqual(
            builder.nextDate(current: Date(day: 1, hour: 5, minute: 24)),
            // plus one day
            Date(day: 2, hour: 5, minute: 23)
        )
    }
    
    func testWeeklyBuilder() throws {
        let builder = ScheduleBuilder()
        builder.weekly().on(.monday).at(.noon)
        // sunday before
        XCTAssertEqual(
            builder.nextDate(current: Date(year: 2019, month: 1, day: 6, hour: 5, minute: 23)),
            // next day at noon
            Date(year: 2019, month: 1, day: 7, hour: 12, minute: 00)
        )
        // monday at 1pm
        XCTAssertEqual(
            builder.nextDate(current: Date(year: 2019, month: 1, day: 7, hour: 13, minute: 00)),
            // next monday at noon
            Date(year: 2019, month: 1, day: 14, hour: 12, minute: 00)
        )
        // monday at 11:30am
        XCTAssertEqual(
            builder.nextDate(current: Date(year: 2019, month: 1, day: 7, hour: 11, minute: 30)),
            // same day at noon
            Date(year: 2019, month: 1, day: 7, hour: 12, minute: 00)
        )
    }
    
    func testMonthlyBuilderFirstDay() throws {
        let builder = ScheduleBuilder()
        builder.monthly().on(.first).at(.noon)
        // middle of jan
        XCTAssertEqual(
            builder.nextDate(current: Date(year: 2019, month: 1, day: 15, hour: 5, minute: 23)),
            // first of feb
            Date(year: 2019, month: 2, day: 1, hour: 12, minute: 00)
        )
        // just before
        XCTAssertEqual(
            builder.nextDate(current: Date(year: 2019, month: 2, day: 1, hour: 11, minute: 30)),
            // first of feb
            Date(year: 2019, month: 2, day: 1, hour: 12, minute: 00)
        )
        // just after
        XCTAssertEqual(
            builder.nextDate(current: Date(year: 2019, month: 2, day: 1, hour: 12, minute: 30)),
            // first of feb
            Date(year: 2019, month: 3, day: 1, hour: 12, minute: 00)
        )
    }
    
    func testMonthlyBuilder15th() throws {
        let builder = ScheduleBuilder()
        builder.monthly().on(15).at(.noon)
        // just before
        XCTAssertEqual(
            builder.nextDate(current: Date(year: 2019, month: 2, day: 15, hour: 11, minute: 30)),
            // first of feb
            Date(year: 2019, month: 2, day: 15, hour: 12, minute: 00)
        )
        // just after
        XCTAssertEqual(
            builder.nextDate(current: Date(year: 2019, month: 2, day: 15, hour: 12, minute: 30)),
            // first of feb
            Date(year: 2019, month: 3, day: 15, hour: 12, minute: 00)
        )
    }
    
    func testYearlyBuilder() throws {
        let builder = ScheduleBuilder()
        builder.yearly().in(.may).on(23).at("2:58pm")
        // early in the year
        XCTAssertEqual(
            builder.nextDate(current: Date(year: 2019, month: 1, day: 15, hour: 5, minute: 23)),
            // 2019
            Date(year: 2019, month: 5, day: 23, hour: 14, minute: 58)
        )
        // just before
        XCTAssertEqual(
            builder.nextDate(current: Date(year: 2019, month: 5, day: 23, hour: 14, minute: 57)),
            // one minute later
            Date(year: 2019, month: 5, day: 23, hour: 14, minute: 58)
        )
        // just after
        XCTAssertEqual(
            builder.nextDate(current: Date(year: 2019, month: 5, day: 23, hour: 14, minute: 59)),
            // one year later
            Date(year: 2020, month: 5, day: 23, hour: 14, minute: 58)
        )
    }
    
    func testCustomCalendarBuilder() throws {
        
        let est = Calendar.calendar(timezone: "EST")
        let mst = Calendar.calendar(timezone: "MST")
        
        // Create a date at 8:00pm EST
        let estDate = Date(calendar: est, hour: 20, minute: 00)
        
        // Schedule it for 7:00pm MST
        let builder = ScheduleBuilder(calendar: mst)
        builder.daily().at("7:00pm")
        
        XCTAssertEqual(
            builder.nextDate(current: estDate),
            // one hour later
            Date(calendar: est, hour: 21, minute: 00)
        )
    
    }
    
}



final class Cleanup: ScheduledJob {
    func run(context: QueueContext) -> EventLoopFuture<Void> {
        return context.eventLoop.makeSucceededFuture(())
    }
}

extension Date {
    init(
        calendar: Calendar = .current,
        year: Int = 2020,
        month: Int = 1,
        day: Int = 1,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0
    ) {
        self = DateComponents(
            calendar: calendar,
            year: year, month: month, day: day, hour: hour, minute: minute, second: second
        ).date!
    }
}

extension Calendar {
    fileprivate static func calendar(timezone identifier: String) -> Calendar {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar
    }
}
