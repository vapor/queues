import NIO
@testable import Jobs
import XCTest

final class SchedulerTests: XCTestCase {
    
    #warning("TODO: - Uncomment after adding in recurrence rule")
    
//    func testSchedulerCustomConstriants() throws {
//        let yearConstraint = try YearRecurrenceRuleConstraint.atYear(2043)
//        let dayOfWeekConstraint = try DayOfWeekRecurrenceRuleConstraint.atDaysOfWeek([1, 4, 6])
//        let hourConstraint = try HourRecurrenceRuleConstraint.atHoursInRange(lowerBound: 3, upperBound: 8)
//        let secondConstraint = try SecondRecurrenceRuleConstraint.secondStep(11)
//
//        var config = JobsConfig()
//        config.schedule(JobMock<JobDataMock>()).whenConstraintsSatisfied(yearConstraint: yearConstraint,
//                                                                         dayOfWeekConstraint: dayOfWeekConstraint,
//                                                                         hourConstraint: hourConstraint,
//                                                                         secondConstraint: secondConstraint)
//    }
//
//    func testSchedulerYearly() throws {
//        var config = JobsConfig()
//
//        // yearly (single monthOfYear per year)
//        try config.schedule(JobMock<JobDataMock>()).yearly().atMonth(5).atDayOfMonth(17).atHour(19).atMinute(9).atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.yearConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .year, stepConstraint: 1))
//        XCTAssertEqual(config.scheduler.recurrenceRule.monthConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .month, setConstraint: [5]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfMonthConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfMonth, setConstraint: [17]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.hourConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .hour, setConstraint: [19]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .minute, setConstraint: [9]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.secondConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .second, setConstraint: [6]))
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfWeekConstraint)
//
//        try config.schedule(JobMock<JobDataMock>()).yearly().on(.may, 17).atHour(19).atMinute(9).atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.yearConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .year, stepConstraint: 1))
//        XCTAssertEqual(config.scheduler.recurrenceRule.monthConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .month, setConstraint: [5]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfMonthConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfMonth, setConstraint: [17]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.hourConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .hour, setConstraint: [19]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .minute, setConstraint: [9]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.secondConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .second, setConstraint: [6]))
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfWeekConstraint)
//    }
//
//    func testSchedulerMonthly() throws {
//        var config = JobsConfig()
//
//        // monthly (single dayOfMonth per month)
//        try config.schedule(JobMock<JobDataMock>()).monthly().atDayOfMonth(17).atHour(19).atMinute(9).atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.monthConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .month, stepConstraint: 1))
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfMonthConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfMonth, setConstraint: [17]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.hourConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .hour, setConstraint: [19]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .minute, setConstraint: [9]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.secondConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .second, setConstraint: [6]))
//        XCTAssertNil(config.scheduler.recurrenceRule.yearConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfWeekConstraint)
//    }
//
//    func testSchedulerWeekly() throws {
//        var config = JobsConfig()
//
//        // weekly (single dayOfWeek per week)
//        try config.schedule(JobMock<JobDataMock>()).weekly(onDayOfWeek: 5).atHour(19).atMinute(9).atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfWeek, setConstraint: [5]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.hourConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .hour, setConstraint: [19]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .minute, setConstraint: [9]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.secondConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .second, setConstraint: [6]))
//        XCTAssertNil(config.scheduler.recurrenceRule.yearConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.monthConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfMonthConstraint)
//
//
//        // weekly(onDayOfWeek:).at()
//        try config.schedule(JobMock<JobDataMock>()).weekly(onDayOfWeek: 5).at("19:09").atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfWeek, setConstraint: [5]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.hourConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .hour, setConstraint: [19]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .minute, setConstraint: [9]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.secondConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .second, setConstraint: [6]))
//        XCTAssertNil(config.scheduler.recurrenceRule.yearConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.monthConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfMonthConstraint)
//
//        // start of day
//        try config.schedule(JobMock<JobDataMock>()).weekly(onDayOfWeek: 5).at(.startOfDay)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfWeek, setConstraint: [5]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.hourConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .hour, setConstraint: [0]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .minute, setConstraint: [0]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.secondConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .second, setConstraint: [0]))
//        XCTAssertNil(config.scheduler.recurrenceRule.yearConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.monthConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfMonthConstraint)
//
//        // end of day
//        try config.schedule(JobMock<JobDataMock>()).weekly(onDayOfWeek: 5).at(.endOfDay)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfWeek, setConstraint: [5]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.hourConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .hour, setConstraint: [23]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .minute, setConstraint: [59]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.secondConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .second, setConstraint: [59]))
//        XCTAssertNil(config.scheduler.recurrenceRule.yearConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.monthConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfMonthConstraint)
//
//        // noon
//        try config.schedule(JobMock<JobDataMock>()).weekly(onDayOfWeek: 5).at(.noon)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfWeek, setConstraint: [5]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.hourConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .hour, setConstraint: [12]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .minute, setConstraint: [0]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.secondConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .second, setConstraint: [0]))
//        XCTAssertNil(config.scheduler.recurrenceRule.yearConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.monthConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfMonthConstraint)
//
//        // weekly(on:)
//        try config.schedule(JobMock<JobDataMock>()).weekly(on: .thursday).atHour(19).atMinute(9).atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfWeek, setConstraint: [5]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.hourConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .hour, setConstraint: [19]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .minute, setConstraint: [9]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.secondConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .second, setConstraint: [6]))
//        XCTAssertNil(config.scheduler.recurrenceRule.yearConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.monthConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfMonthConstraint)
//    }
//
//
//    func testSchedulerDaily() throws {
//        var config = JobsConfig()
//
//        // daily (single hour per day)
//        try config.schedule(JobMock<JobDataMock>()).daily().atHour(19).atMinute(9).atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .dayOfWeek, stepConstraint: 1))
//        XCTAssertEqual(config.scheduler.recurrenceRule.hourConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .hour, setConstraint: [19]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .minute, setConstraint: [9]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.secondConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .second, setConstraint: [6]))
//        XCTAssertNil(config.scheduler.recurrenceRule.yearConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.monthConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfMonthConstraint)
//
//        try config.schedule(JobMock<JobDataMock>()).daily().at("19:09").atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .dayOfWeek, stepConstraint: 1))
//        XCTAssertEqual(config.scheduler.recurrenceRule.hourConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .hour, setConstraint: [19]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .minute, setConstraint: [9]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.secondConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .second, setConstraint: [6]))
//        XCTAssertNil(config.scheduler.recurrenceRule.yearConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.monthConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfMonthConstraint)
//
//        // startOfDay
//        try config.schedule(JobMock<JobDataMock>()).daily().at(.startOfDay)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .dayOfWeek, stepConstraint: 1))
//        XCTAssertEqual(config.scheduler.recurrenceRule.hourConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .hour, setConstraint: [0]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .minute, setConstraint: [0]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.secondConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .second, setConstraint: [0]))
//        XCTAssertNil(config.scheduler.recurrenceRule.yearConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.monthConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfMonthConstraint)
//
//        // endOfDay
//        try config.schedule(JobMock<JobDataMock>()).daily().at(.endOfDay)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .dayOfWeek, stepConstraint: 1))
//        XCTAssertEqual(config.scheduler.recurrenceRule.hourConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .hour, setConstraint: [23]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .minute, setConstraint: [59]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.secondConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .second, setConstraint: [59]))
//        XCTAssertNil(config.scheduler.recurrenceRule.yearConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.monthConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfMonthConstraint)
//
//        // noon
//        try config.schedule(JobMock<JobDataMock>()).daily().at(.noon)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .dayOfWeek, stepConstraint: 1))
//        XCTAssertEqual(config.scheduler.recurrenceRule.hourConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .hour, setConstraint: [12]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .minute, setConstraint: [0]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.secondConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .second, setConstraint: [0]))
//        XCTAssertNil(config.scheduler.recurrenceRule.yearConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.monthConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfMonthConstraint)
//
//
//        // test day of week combinations
//        try config.schedule(JobMock<JobDataMock>()).weekdays().atHour(19).atMinute(9).atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfWeek, setConstraint: [2, 3, 4, 5, 6]))
//
//        try config.schedule(JobMock<JobDataMock>()).weekends().atHour(19).atMinute(9).atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfWeek, setConstraint: [1, 7]))
//
//        try config.schedule(JobMock<JobDataMock>()).sundays().atHour(19).atMinute(9).atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfWeek, setConstraint: [1]))
//
//        try config.schedule(JobMock<JobDataMock>()).mondays().atHour(19).atMinute(9).atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfWeek, setConstraint: [2]))
//
//        try config.schedule(JobMock<JobDataMock>()).tuesdays().atHour(19).atMinute(9).atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfWeek, setConstraint: [3]))
//
//        try config.schedule(JobMock<JobDataMock>()).wednesdays().atHour(19).atMinute(9).atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfWeek, setConstraint: [4]))
//
//        try config.schedule(JobMock<JobDataMock>()).thursdays().atHour(19).atMinute(9).atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfWeek, setConstraint: [5]))
//
//        try config.schedule(JobMock<JobDataMock>()).fridays().atHour(19).atMinute(9).atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfWeek, setConstraint: [6]))
//
//        try config.schedule(JobMock<JobDataMock>()).saturdays().atHour(19).atMinute(9).atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.dayOfWeekConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .dayOfWeek, setConstraint: [7]))
//    }
//
//    func testSchedulerHourly() throws {
//        var config = JobsConfig()
//
//        // hourly (single minute per hour)
//        try config.schedule(JobMock<JobDataMock>()).hourly().atMinute(9).atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.hourConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .hour, stepConstraint: 1))
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .minute, setConstraint: [9]))
//        XCTAssertEqual(config.scheduler.recurrenceRule.secondConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .second, setConstraint: [6]))
//        XCTAssertNil(config.scheduler.recurrenceRule.yearConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.monthConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfMonthConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfWeekConstraint)
//    }
//
//    func testSchedulerEveryXMinutes() throws {
//        var config = JobsConfig()
//
//        // everyXMinutes (single second per minute)
//        try config.schedule(JobMock<JobDataMock>()).everyMinute().atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .minute, stepConstraint: 1))
//        XCTAssertEqual(config.scheduler.recurrenceRule.secondConstraint as? RecurrenceRuleSetConstraint,
//                       try RecurrenceRuleSetConstraint.init(timeUnit: .second, setConstraint: [6]))
//        XCTAssertNil(config.scheduler.recurrenceRule.yearConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.monthConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfMonthConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.dayOfWeekConstraint)
//        XCTAssertNil(config.scheduler.recurrenceRule.hourConstraint)
//
//        // other factors of 60
//        // 2
//        try config.schedule(JobMock<JobDataMock>()).everyTwoMinutes().atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .minute, stepConstraint: 2))
//
//        // 3
//        try config.schedule(JobMock<JobDataMock>()).everyThreeMinutes().atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .minute, stepConstraint: 3))
//
//        // 4
//        try config.schedule(JobMock<JobDataMock>()).everyFourMinutes().atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .minute, stepConstraint: 4))
//
//        // 5
//        try config.schedule(JobMock<JobDataMock>()).everyFiveMinutes().atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .minute, stepConstraint: 5))
//
//        // 6
//        try config.schedule(JobMock<JobDataMock>()).everySixMinutes().atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .minute, stepConstraint: 6))
//
//        // 10
//        try config.schedule(JobMock<JobDataMock>()).everyTenMinutes().atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .minute, stepConstraint: 10))
//
//        // 12
//        try config.schedule(JobMock<JobDataMock>()).everyTwelveMinutes().atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .minute, stepConstraint: 12))
//
//        // 15
//        try config.schedule(JobMock<JobDataMock>()).everyFifteenMinutes().atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .minute, stepConstraint: 15))
//
//        // 20
//        try config.schedule(JobMock<JobDataMock>()).everyTwentyMinutes().atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .minute, stepConstraint: 20))
//
//        // 30
//        try config.schedule(JobMock<JobDataMock>()).everyThirtyMinutes().atSecond(6)
//        XCTAssertEqual(config.scheduler.recurrenceRule.minuteConstraint as? RecurrenceRuleStepConstraint,
//                       try RecurrenceRuleStepConstraint.init(timeUnit: .minute, stepConstraint: 30))
//    }
//
//    static var allTests = [
//        ("testSchedulerCustomConstriants", testSchedulerCustomConstriants),
//        ("testSchedulerYearly", testSchedulerYearly),
//        ("testSchedulerMonthly", testSchedulerMonthly),
//        ("testSchedulerWeekly", testSchedulerWeekly),
//        ("testSchedulerDaily", testSchedulerDaily),
//        ("testSchedulerHourly", testSchedulerHourly),
//        ("testSchedulerEveryXMinutes", testSchedulerEveryXMinutes)
//    ]
//
}
