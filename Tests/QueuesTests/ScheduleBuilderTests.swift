import Queues
import XCTest

final class ScheduleContainerTests: XCTestCase {
    
    func testHourlyBuilder() throws {
        let builderContainer = ScheduleBuilderContainer()
        let builder = ScheduleBuilderContainer.Builder(container: builderContainer)
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
        let builderContainer = ScheduleBuilderContainer()
        let builder = ScheduleBuilderContainer.Builder(container: builderContainer)
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
        let builderContainer = ScheduleBuilderContainer()
        let builder = ScheduleBuilderContainer.Builder(container: builderContainer)
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
        let builderContainer = ScheduleBuilderContainer()
        let builder = ScheduleBuilderContainer.Builder(container: builderContainer)
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
        let builderContainer = ScheduleBuilderContainer()
        let builder = ScheduleBuilderContainer.Builder(container: builderContainer)
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
        let builderContainer = ScheduleBuilderContainer()
        let builder = ScheduleBuilderContainer.Builder(container: builderContainer)
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
    
    // Test `.every` functions.
    func testEveryBuildHelper() throws {
        
        // As explained in `ScheduleBuilderContainer.Builder.every(_:in:underestimatedCount:)`
        // when using `.every`, the current builder gets populated with the first job's
        // schedule time, and for the next schedule times we'll have new builders created
        // and added to the container.
        
        // Test to make sure builders made with `.every` function will have different `.nextDate()`s
        do {
            let builderContainer = ScheduleBuilderContainer()
            let initialBuilder = ScheduleBuilderContainer.Builder(container: builderContainer)
            initialBuilder.minutely().every(.seconds(24))
            let builders = builderContainer.builders
            
            XCTAssertNotEqual(builders[0].nextDate(), builders[1].nextDate())
            XCTAssertNotEqual(builders[0].nextDate(), builders[2].nextDate())
            XCTAssertNotEqual(builders[1].nextDate(), builders[2].nextDate())
        }
        
        // Repeating the exact same tests in `testHourlyBuilder()` using a builder
        // that is made using the `.every` function.
        // Results must stay the same with this new builder.
        do {
            let builderContainer = ScheduleBuilderContainer()
            let initialBuilder = ScheduleBuilderContainer.Builder(container: builderContainer)
            initialBuilder.hourly().every(.minutes(30))
            let builder = builderContainer.builders[1]
            
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
        
        // MARK: tests for the correct amount of made builders
        
        do {
            let builderContainer = ScheduleBuilderContainer()
            let builder = ScheduleBuilderContainer.Builder(container: builderContainer)
            builder.minutely().every(.seconds(10))
            XCTAssertEqual(builderContainer.builders.count, 6)
        }
        
        do {
            let builderContainer = ScheduleBuilderContainer()
            let builder = ScheduleBuilderContainer.Builder(container: builderContainer)
            builder.hourly().every(.seconds(66))
            XCTAssertEqual(builderContainer.builders.count, 55)
        }
        
        do {
            let builderContainer = ScheduleBuilderContainer()
            let builder = ScheduleBuilderContainer.Builder(container: builderContainer)
            builder.hourly().every(.minutes(60))
            XCTAssertEqual(builderContainer.builders.count, 1)
        }
        
        do {
            let builderContainer = ScheduleBuilderContainer()
            let builder = ScheduleBuilderContainer.Builder(container: builderContainer)
            builder.every(.minutes(12), in: .hours(24), underestimatedCount: true)
            XCTAssertEqual(builderContainer.builders.count, 120)
        }
        
        do {
            let builderContainer = ScheduleBuilderContainer()
            let builder = ScheduleBuilderContainer.Builder(container: builderContainer)
            builder.every(.milliseconds(90), in: .seconds(1), underestimatedCount: true)
            XCTAssertEqual(builderContainer.builders.count, 11)
        }
        
    }
    
}



final class Cleanup: ScheduledJob {
    func run(context: QueueContext) -> EventLoopFuture<Void> {
        return context.eventLoop.makeSucceededFuture(())
    }
}

extension Date {
    var year: Int {
        Calendar.current.component(.year, from: self)
    }
    
    var month: Int {
        Calendar.current.component(.month, from: self)
    }
    
    var weekday: Int {
        Calendar.current.component(.weekday, from: self)
    }
    
    var day: Int {
        Calendar.current.component(.day, from: self)
    }
    
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }
    
    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }
    
    var second: Int {
        Calendar.current.component(.second, from: self)
    }
    
    init(
        year: Int = 2020,
        month: Int = 1,
        day: Int = 1,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0
    ) {
        self = DateComponents(
            calendar: .current,
            year: year, month: month, day: day, hour: hour, minute: minute, second: second
        ).date!
    }
}
