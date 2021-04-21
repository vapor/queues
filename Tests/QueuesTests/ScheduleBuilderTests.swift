@testable import Queues
import Vapor
import XCTest

final class ScheduleContainerTests: XCTestCase {

    func testHourlyBuilder() throws {
        let builderContainer = ScheduleContainer(job: Cleanup())
        let builder = ScheduleContainer.Builder(container: builderContainer)
        builder.hourly().at(30)

        // same time
        XCTAssertEqual(
            builder._nextDate(current: Date(hour: 5, minute: 30)),
            // plus one hour
            Date(hour: 6, minute: 30)
        )
        // just before
        XCTAssertEqual(
            builder._nextDate(current: Date(hour: 5, minute: 29)),
            // plus one minute
            Date(hour: 5, minute: 30)
        )
        // just after
        XCTAssertEqual(
            builder._nextDate(current: Date(hour: 5, minute: 31)),
            // plus one hour
            Date(hour: 6, minute: 30)
        )
    }

    func testDailyBuilder() throws {
        let builderContainer = ScheduleContainer(job: Cleanup())
        let builder = ScheduleContainer.Builder(container: builderContainer)
        builder.daily().at("5:23am")
        // same time
        XCTAssertEqual(
            builder._nextDate(current: Date(day: 1, hour: 5, minute: 23)),
            // plus one day
            Date(day: 2, hour: 5, minute: 23)
        )
        // just before
        XCTAssertEqual(
            builder._nextDate(current: Date(day: 1, hour: 5, minute: 22)),
            // plus one minute
            Date(day: 1, hour: 5, minute: 23)
        )
        // just after
        XCTAssertEqual(
            builder._nextDate(current: Date(day: 1, hour: 5, minute: 24)),
            // plus one day
            Date(day: 2, hour: 5, minute: 23)
        )
    }

    func testWeeklyBuilder() throws {
        let builderContainer = ScheduleContainer(job: Cleanup())
        let builder = ScheduleContainer.Builder(container: builderContainer)
        builder.weekly().on(.monday).at(.noon)
        // sunday before
        XCTAssertEqual(
            builder._nextDate(current: Date(year: 2019, month: 1, day: 6, hour: 5, minute: 23)),
            // next day at noon
            Date(year: 2019, month: 1, day: 7, hour: 12, minute: 00)
        )
        // monday at 1pm
        XCTAssertEqual(
            builder._nextDate(current: Date(year: 2019, month: 1, day: 7, hour: 13, minute: 00)),
            // next monday at noon
            Date(year: 2019, month: 1, day: 14, hour: 12, minute: 00)
        )
        // monday at 11:30am
        XCTAssertEqual(
            builder._nextDate(current: Date(year: 2019, month: 1, day: 7, hour: 11, minute: 30)),
            // same day at noon
            Date(year: 2019, month: 1, day: 7, hour: 12, minute: 00)
        )
    }

    func testMonthlyBuilderFirstDay() throws {
        let builderContainer = ScheduleContainer(job: Cleanup())
        let builder = ScheduleContainer.Builder(container: builderContainer)
        builder.monthly().on(.first).at(.noon)

        // middle of jan
        XCTAssertEqual(
            builder._nextDate(current: Date(year: 2019, month: 1, day: 15, hour: 5, minute: 23)),
            // first of feb
            Date(year: 2019, month: 2, day: 1, hour: 12, minute: 00)
        )
        // just before
        XCTAssertEqual(
            builder._nextDate(current: Date(year: 2019, month: 2, day: 1, hour: 11, minute: 30)),
            // first of feb
            Date(year: 2019, month: 2, day: 1, hour: 12, minute: 00)
        )
        // just after
        XCTAssertEqual(
            builder._nextDate(current: Date(year: 2019, month: 2, day: 1, hour: 12, minute: 30)),
            // first of feb
            Date(year: 2019, month: 3, day: 1, hour: 12, minute: 00)
        )
    }

    func testMonthlyBuilder15th() throws {
        let builderContainer = ScheduleContainer(job: Cleanup())
        let builder = ScheduleContainer.Builder(container: builderContainer)
        builder.monthly().on(15).at(.noon)
        // just before
        XCTAssertEqual(
            builder._nextDate(current: Date(year: 2019, month: 2, day: 15, hour: 11, minute: 30)),
            // first of feb
            Date(year: 2019, month: 2, day: 15, hour: 12, minute: 00)
        )
        // just after
        XCTAssertEqual(
            builder._nextDate(current: Date(year: 2019, month: 2, day: 15, hour: 12, minute: 30)),
            // first of feb
            Date(year: 2019, month: 3, day: 15, hour: 12, minute: 00)
        )
    }

    func testYearlyBuilder() throws {
        let builderContainer = ScheduleContainer(job: Cleanup())
        let builder = ScheduleContainer.Builder(container: builderContainer)
        builder.yearly().in(.may).on(23).at("2:58pm")
        // early in the year
        XCTAssertEqual(
            builder._nextDate(current: Date(year: 2019, month: 1, day: 15, hour: 5, minute: 23)),
            // 2019
            Date(year: 2019, month: 5, day: 23, hour: 14, minute: 58)
        )
        // just before
        XCTAssertEqual(
            builder._nextDate(current: Date(year: 2019, month: 5, day: 23, hour: 14, minute: 57)),
            // one minute later
            Date(year: 2019, month: 5, day: 23, hour: 14, minute: 58)
        )
        // just after
        XCTAssertEqual(
            builder._nextDate(current: Date(year: 2019, month: 5, day: 23, hour: 14, minute: 59)),
            // one year later
            Date(year: 2020, month: 5, day: 23, hour: 14, minute: 58)
        )
    }

    // Test `.every()` functions.
    func testEveryBuildHelper() throws {

        // As explained in `ScheduleBuilderContainer.Builder.every(_:in:underestimatedCount:)`
        // when using `.every`, the current builder gets populated with the first job's
        // schedule time, and for the next schedule times we'll have new builders created
        // and added to the container.

        // Test to make sure builders made with `.every` function will have different `._nextDate()`s
        do {
            let builderContainer = ScheduleContainer(job: Cleanup())
            let builder = ScheduleContainer.Builder(container: builderContainer)
            builder.minutely().every(.seconds(19))
            let builders = builderContainer.builders

            let date0 = builders[0]._nextDate()
            let date1 = builders[1]._nextDate()
            let date2 = builders[2]._nextDate()
            XCTAssertNotEqual(date0, date1)
            XCTAssertNotEqual(date0, date2)
            XCTAssertNotEqual(date1, date2)
        }
        
        // MARK: Testing for expected times that `nextDate()` should return
        
        do {
            let builderContainer = ScheduleContainer(job: Cleanup())
            let builder = ScheduleContainer.Builder(container: builderContainer)
            builder.hourly().every(.minutes(30))
            let builder2 = builderContainer.builders[1]

            XCTAssertEqual(
                builder._nextDate(current: Date(hour: 5, minute: 30)),
                // plus one hour
                Date(hour: 5, minute: 30, second: 1)
            )
            XCTAssertEqual(
                builder._nextDate(current: Date(hour: 5, minute: 30)),
                Date(hour: 6, minute: 30)
            )
            XCTAssertEqual(
                builder2._nextDate(current: Date(hour: 5, minute: 30)),
                Date(hour: 6, minute: 00, second: 1)
            )
        }

        do {
            let builderContainer = ScheduleContainer(job: Cleanup())
            let builder = ScheduleContainer.Builder(container: builderContainer)
            builder.every(.seconds(5), in: .seconds(22))

            let expectedAdditionalSeconds = [1, 6, 11, 16, 21]
            builderContainer.builders.enumerated().forEach { index, builder in
                let nextDate = builder.nextDate()!.timeIntervalSinceReferenceDate
                let expected = Date().addingTimeInterval(Double(expectedAdditionalSeconds[index]))
                    .timeIntervalSinceReferenceDate
                // Comparing the two times with millisecond precision
                XCTAssertEqual(Int(nextDate * 1000), Int(expected * 1000))
            }
        }

        // MARK: Tests for the correct amount of made builders

        do {
            let builderContainer = ScheduleContainer(job: Cleanup())
            let builder = ScheduleContainer.Builder(container: builderContainer)
            builder.minutely().every(.seconds(10))
            XCTAssertEqual(builderContainer.builders.count, 6)
        }

        do {
            let builderContainer = ScheduleContainer(job: Cleanup())
            let builder = ScheduleContainer.Builder(container: builderContainer)
            builder.hourly().every(.seconds(66))
            XCTAssertEqual(builderContainer.builders.count, 54)
        }

        do {
            let builderContainer = ScheduleContainer(job: Cleanup())
            let builder = ScheduleContainer.Builder(container: builderContainer)
            builder.hourly().every(.minutes(60))
            XCTAssertEqual(builderContainer.builders.count, 1)
        }

        do {
            let builderContainer = ScheduleContainer(job: Cleanup())
            let builder = ScheduleContainer.Builder(container: builderContainer)
            builder.every(.minutes(12), in: .hours(24), underestimatedCount: false)
            XCTAssertEqual(builderContainer.builders.count, 120)
        }

        do {
            let builderContainer = ScheduleContainer(job: Cleanup())
            let builder = ScheduleContainer.Builder(container: builderContainer)
            builder.every(.milliseconds(90), in: .seconds(1), underestimatedCount: false)
            XCTAssertEqual(builderContainer.builders.count, 12)
        }

        /// Testing `QueuesConfiguration`'s container management in `startScheduledJobs()` func
        do {
            let app = Application()
            app.queues.schedule(Cleanup3()).every(.seconds(7), in: .seconds(14))
            app.queues.schedule(Cleanup()).every(.seconds(10), in: .seconds(10))
            app.queues.schedule(Cleanup2()).every(.seconds(2), in: .seconds(18))
            app.queues.schedule(Cleanup3()).every(.seconds(5), in: .seconds(40))
            app.queues.schedule(Cleanup()).every(.seconds(10), in: .seconds(20))
            app.queues.schedule(Cleanup3()).every(.seconds(1), in: .seconds(11))
            app.queues.schedule(Cleanup2()).every(.seconds(1), in: .seconds(17))
            app.queues.schedule(Cleanup()).every(.seconds(10), in: .seconds(40))

            try? app.queues.startScheduledJobs()
            let containers = app.queues.configuration.scheduledJobsContainers
            XCTAssertEqual(containers.count, 3)
            XCTAssertEqual(containers[0].builders.count, 21)
            XCTAssertEqual(containers[1].builders.count, 7)
            XCTAssertEqual(containers[2].builders.count, 26)
        }

    }

}


final class Cleanup: ScheduledJob {
    func run(context: QueueContext) -> EventLoopFuture<Void> {
        return context.eventLoop.makeSucceededFuture(())
    }
}

final class Cleanup2: ScheduledJob {
    func run(context: QueueContext) -> EventLoopFuture<Void> {
        return context.eventLoop.makeSucceededFuture(())
    }
}

final class Cleanup3: ScheduledJob {
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
