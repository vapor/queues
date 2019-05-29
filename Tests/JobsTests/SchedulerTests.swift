import XCTest
import NIO
@testable import Jobs

final class SchedulerTests: XCTestCase {

    func testCustomConstriants() throws {
        let yearConstraint = try YearRecurrenceRuleConstraint.atYear(2043)
        let dayOfWeekConstraint = try DayOfWeekRecurrenceRuleConstraint.atDaysOfWeek([1, 4, 6])
        let hourConstraint = try HourRecurrenceRuleConstraint.atHoursInRange(lowerBound: 3, upperBound: 8)
        let secondConstraint = try SecondRecurrenceRuleConstraint.secondStep(11)

        //let emailJob = EmailJob(to: "to@to.com", from: "from@from.com", message: "message")
        Scheduler().whenConstraintsSatisfied(yearConstraint: yearConstraint,
                                                    dayOfWeekConstraint: dayOfWeekConstraint,
                                                    hourConstraint: hourConstraint,
                                                    secondConstraint: secondConstraint)
    }

    func testScheduler() throws {
        // yearly (single monthOfYear per year)
        try Scheduler().yearly().atMonth(5).atDayOfMonth(28).atHour(4).atMinute(30).atSecond(45)
        try Scheduler().yearly().on(.may, 17).atHour(19).atMinute(9).atSecond(6)

        // monthly (single dayOfMonth per month)
        try Scheduler().monthly().atDayOfMonth(17).atHour(19).atMinute(9).atSecond(6)

        // weekly (single dayOfWeek per week)
        try Scheduler().weekly(onDayOfWeek: 5).atHour(19).atMinute(9).atSecond(6)
        try Scheduler().weekly(onDayOfWeek: 5).at("19:09").atSecond(6)
        try Scheduler().weekly(onDayOfWeek: 5).at(.startOfDay)
        try Scheduler().weekly(onDayOfWeek: 5).at(.endOfDay)
        try Scheduler().weekly(onDayOfWeek: 5).at(.noon)
        try Scheduler().weekly(on: .friday).atHour(19).atMinute(9).atSecond(6)

        // daily (single hour per day)
        try Scheduler().daily().atHour(19).atMinute(9).atSecond(6)
        try Scheduler().daily().at("19:09").atSecond(6)
        try Scheduler().daily().at(.startOfDay)
        try Scheduler().daily().at(.endOfDay)
        try Scheduler().daily().at(.noon)
        try Scheduler().weekdays().atHour(19).atMinute(9).atSecond(6)
        try Scheduler().weekends().atHour(19).atMinute(9).atSecond(6)
        try Scheduler().mondays().atHour(19).atMinute(9).atSecond(6)
        try Scheduler().tuesdays().atHour(19).atMinute(9).atSecond(6)
        try Scheduler().wednesdays().atHour(19).atMinute(9).atSecond(6)
        try Scheduler().thursdays().atHour(19).atMinute(9).atSecond(6)
        try Scheduler().fridays().atHour(19).atMinute(9).atSecond(6)
        try Scheduler().saturdays().atHour(19).atMinute(9).atSecond(6)
        try Scheduler().sundays().atHour(19).atMinute(9).atSecond(6)

        // hourly (single minute per hour)
        try Scheduler().hourly().atMinute(9).atSecond(6)

        // everyXMinutes (single second per minute)
        try Scheduler().everyMinute().atSecond(6)
        try Scheduler().everyTwoMinutes().atSecond(6)
        try Scheduler().everyThreeMinutes().atSecond(6)
        try Scheduler().everyFourMinutes().atSecond(6)
        try Scheduler().everyFiveMinutes().atSecond(6)
        try Scheduler().everySixMinutes().atSecond(6)
        try Scheduler().everyTenMinutes().atSecond(6)
        try Scheduler().everyTwelveMinutes().atSecond(6)
        try Scheduler().everyTwentyMinutes().atSecond(6)
        try Scheduler().everyThirtyMinutes().atSecond(6)
    }

    static var allTests = [
        ("testCustomConstriants", testCustomConstriants),
        ("testScheduler", testScheduler)
    ]
}
