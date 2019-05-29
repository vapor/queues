import XCTest
import NIO
@testable import Jobs

final class SchedulerTests: XCTestCase {

    func testSchedulerCustomConstriants() throws {
        let yearConstraint = try YearRecurrenceRuleConstraint.atYear(2043)
        let dayOfWeekConstraint = try DayOfWeekRecurrenceRuleConstraint.atDaysOfWeek([1, 4, 6])
        let hourConstraint = try HourRecurrenceRuleConstraint.atHoursInRange(lowerBound: 3, upperBound: 8)
        let secondConstraint = try SecondRecurrenceRuleConstraint.secondStep(11)

        var config = JobsConfig()
        config.schedule(JobMock<JobDataMock>()).whenConstraintsSatisfied(yearConstraint: yearConstraint,
                                                                             dayOfWeekConstraint: dayOfWeekConstraint,
                                                                             hourConstraint: hourConstraint,
                                                                             secondConstraint: secondConstraint)
    }

    func testScheduler() throws {
        var config = JobsConfig()

        // other
        try config.schedule(JobMock<JobDataMock>()).hourly().atMinute(9).atSecond(6)
        XCTAssertNotNil(config.scheduler.recurrenceRule.hourConstraint)
        XCTAssertNotNil(config.scheduler.recurrenceRule.minuteConstraint)
        XCTAssertNotNil(config.scheduler.recurrenceRule.secondConstraint)

        // yearly (single monthOfYear per year)
        try config.schedule(JobMock<JobDataMock>()).yearly().atMonth(5).atDayOfMonth(28).atHour(4).atMinute(30).atSecond(45)
        try config.schedule(JobMock<JobDataMock>()).yearly().on(.may, 17).atHour(19).atMinute(9).atSecond(6)

        // monthly (single dayOfMonth per month)
        try config.schedule(JobMock<JobDataMock>()).monthly().atDayOfMonth(17).atHour(19).atMinute(9).atSecond(6)
        XCTAssertNil(config.scheduler.recurrenceRule.yearConstraint)
        XCTAssertNotNil(config.scheduler.recurrenceRule.monthConstraint)
        XCTAssertNotNil(config.scheduler.recurrenceRule.hourConstraint)
        XCTAssertNotNil(config.scheduler.recurrenceRule.minuteConstraint)
        XCTAssertNotNil(config.scheduler.recurrenceRule.secondConstraint)

        // weekly (single dayOfWeek per week)
        try config.schedule(JobMock<JobDataMock>()).weekly(onDayOfWeek: 5).atHour(19).atMinute(9).atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).weekly(onDayOfWeek: 5).at("19:09").atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).weekly(onDayOfWeek: 5).at(.startOfDay)
        try config.schedule(JobMock<JobDataMock>()).weekly(onDayOfWeek: 5).at(.endOfDay)
        try config.schedule(JobMock<JobDataMock>()).weekly(onDayOfWeek: 5).at(.noon)
        try config.schedule(JobMock<JobDataMock>()).weekly(on: .friday).atHour(19).atMinute(9).atSecond(6)

        // daily (single hour per day)
        try config.schedule(JobMock<JobDataMock>()).daily().atHour(19).atMinute(9).atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).daily().at("19:09").atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).daily().at(.startOfDay)
        try config.schedule(JobMock<JobDataMock>()).daily().at(.endOfDay)
        try config.schedule(JobMock<JobDataMock>()).daily().at(.noon)
        try config.schedule(JobMock<JobDataMock>()).weekdays().atHour(19).atMinute(9).atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).weekends().atHour(19).atMinute(9).atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).mondays().atHour(19).atMinute(9).atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).tuesdays().atHour(19).atMinute(9).atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).wednesdays().atHour(19).atMinute(9).atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).thursdays().atHour(19).atMinute(9).atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).fridays().atHour(19).atMinute(9).atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).saturdays().atHour(19).atMinute(9).atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).sundays().atHour(19).atMinute(9).atSecond(6)

        // hourly (single minute per hour)
        try config.schedule(JobMock<JobDataMock>()).hourly().atMinute(9).atSecond(6)

        // everyXMinutes (single second per minute)
        try config.schedule(JobMock<JobDataMock>()).everyMinute().atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).everyTwoMinutes().atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).everyThreeMinutes().atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).everyFourMinutes().atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).everyFiveMinutes().atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).everySixMinutes().atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).everyTenMinutes().atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).everyTwelveMinutes().atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).everyTwentyMinutes().atSecond(6)
        try config.schedule(JobMock<JobDataMock>()).everyThirtyMinutes().atSecond(6)
    }

}
