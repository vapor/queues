import Foundation
import Queues
import XCTest

final class ScheduleBuilderTests: XCTestCase {
    override class func setUp() {
        XCTAssert(isLoggingConfigured)
    }

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
    
    func testTimezoneConfiguration() throws {
        // Test timezone initialization
        let nyBuilder = ScheduleBuilder()
            .in(timezone: TimeZone(identifier: "America/New_York")!)
        
        // Schedule job for 9am New York time
        nyBuilder.daily().at("9:00am")
        
        // Reference dates
        let nyDate = Date(
            calendar: .calendar(timezone: "America/New_York"),
            hour: 9, 
            minute: 0
        )
        
        let utcDate = Date(
            calendar: .calendar(timezone: "UTC"),
            hour: 14,  // 9am NY = 2pm UTC
            minute: 0
        )
        
        // Test that next run time is correct regardless of input timezone
        XCTAssertEqual(
            nyBuilder.nextDate(current: nyDate.addingTimeInterval(-3600)),
            nyDate
        )
        XCTAssertEqual(
            nyBuilder.nextDate(current: utcDate.addingTimeInterval(-3600)),
            utcDate
        )
    }
    
    func testTimezoneAcrossDateBoundary() throws {
        let tokyoBuilder = ScheduleBuilder()
            .in(timezone: TimeZone(identifier: "Asia/Tokyo")!)
        
        // Schedule for midnight Tokyo time
        tokyoBuilder.daily().at(.midnight)
        
        // Create a reference date: January 1, 2020 11:00 PM Los Angeles time
        // At this time, it's already January 2, 2020 4:00 PM in Tokyo
        let laDate = Date(
            calendar: .calendar(timezone: "America/Los_Angeles"),
            year: 2020,
            month: 1,
            day: 1,
            hour: 23,  // 11 PM LA time
            minute: 0
        )
        
        // The next midnight in Tokyo (January 3, 2020 00:00 Tokyo time)
        // will be January 2, 2020 7:00 AM LA time
        let expectedDate = Date(
            calendar: .calendar(timezone: "America/Los_Angeles"),
            year: 2020,
            month: 1,
            day: 2,
            hour: 7,   // 7 AM LA = midnight Tokyo (next day)
            minute: 0
        )
        
        XCTAssertEqual(
            tokyoBuilder.nextDate(current: laDate),
            expectedDate,
            "When it's 11 PM on Jan 1 in LA, the next midnight in Tokyo should be 7 AM on Jan 2 LA time"
        )
    }
    
    func testTimezoneWithYearlySchedule() throws {
        let dubaiBuilder = ScheduleBuilder()
            .in(timezone: TimeZone(identifier: "Asia/Dubai")!)
        
        // Schedule for New Year's Day at noon Dubai time
        dubaiBuilder.yearly()
            .in(.january)
            .on(.first)
            .at(.noon)
        
        // Test from December 31st London time
        let londonDate = Date(
            calendar: .calendar(timezone: "Europe/London"),
            year: 2020,    // Add explicit year
            month: 12,
            day: 31,
            hour: 8,      // 8am London = noon Dubai
            minute: 0
        )
        
        let expectedDate = Date(
            calendar: .calendar(timezone: "Europe/London"),
            year: 2021,    // Next year
            month: 1,
            day: 1,
            hour: 8,      // 8am London = noon Dubai
            minute: 0
        )
        
        XCTAssertEqual(
            dubaiBuilder.nextDate(current: londonDate),
            expectedDate
        )
    }
    
    func testTimezoneConsistency() throws {
        let sydneyBuilder = ScheduleBuilder()
            .in(timezone: TimeZone(identifier: "Australia/Sydney")!)
        
        // Schedule for 3pm Sydney time
        sydneyBuilder.daily().at("3:00pm")
        
        // Test across multiple days to ensure DST handling
        let startDate = Date(
            calendar: .calendar(timezone: "Australia/Sydney"),
            month: 4,  // April (DST transition month in Australia)
            day: 1,
            hour: 15,
            minute: 0
        )
        
        var currentDate = startDate
        for _ in 1...5 {
            let nextDate = sydneyBuilder.nextDate(current: currentDate)
            XCTAssertNotNil(nextDate)
            
            // Verify time remains at 3pm Sydney time
            let components = Calendar.calendar(timezone: "Australia/Sydney")
                .dateComponents([.hour, .minute], from: nextDate!)
            
            XCTAssertEqual(components.hour, 15)  // 3pm = 15:00
            XCTAssertEqual(components.minute, 0)
            
            currentDate = nextDate!
        }
    }
}

final class Cleanup: ScheduledJob {
    func run(context: QueueContext) -> EventLoopFuture<Void> {
        context.eventLoop.makeSucceededVoidFuture()
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
