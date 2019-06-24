import XCTest
import NIO
@testable import Jobs

final class RecurrenceRuleConstraintTests: XCTestCase {

    func testRecurrenceRuleConstraintCreationSetSingleValue() throws {
        // second (0-59)
        XCTAssertThrowsError(try SecondRecurrenceRuleConstraint.atSecond(-1))
        XCTAssertNoThrow(try SecondRecurrenceRuleConstraint.atSecond(0))
        XCTAssertNoThrow(try SecondRecurrenceRuleConstraint.atSecond(59))
        XCTAssertThrowsError(try SecondRecurrenceRuleConstraint.atSecond(60))

        // minute (0-59)
        XCTAssertThrowsError(try MinuteRecurrenceRuleConstraint.atMinute(-1))
        XCTAssertNoThrow(try MinuteRecurrenceRuleConstraint.atMinute(0))
        XCTAssertNoThrow(try MinuteRecurrenceRuleConstraint.atMinute(59))
        XCTAssertThrowsError(try MinuteRecurrenceRuleConstraint.atMinute(60))

        // hour (0-23)
        XCTAssertThrowsError(try HourRecurrenceRuleConstraint.atHour(-1))
        XCTAssertNoThrow(try HourRecurrenceRuleConstraint.atHour(0))
        XCTAssertNoThrow(try HourRecurrenceRuleConstraint.atHour(23))
        XCTAssertThrowsError(try HourRecurrenceRuleConstraint.atHour(24))

        // dayOfWeek (1-7) ex: 1 sunday, 7 saturday
        XCTAssertThrowsError(try DayOfWeekRecurrenceRuleConstraint.atDayOfWeek(0))
        XCTAssertNoThrow(try DayOfWeekRecurrenceRuleConstraint.atDayOfWeek(1))
        XCTAssertNoThrow(try DayOfWeekRecurrenceRuleConstraint.atDayOfWeek(7))
        XCTAssertThrowsError(try DayOfWeekRecurrenceRuleConstraint.atDayOfWeek(8))

        // dayOfMonth (1-31) ex: 1 is the 1st of month, 31 is the 31st of month
        XCTAssertThrowsError(try DayOfMonthRecurrenceRuleConstraint.atDayOfMonth(0))
        XCTAssertNoThrow(try DayOfMonthRecurrenceRuleConstraint.atDayOfMonth(1))
        XCTAssertNoThrow(try DayOfMonthRecurrenceRuleConstraint.atDayOfMonth(31))
        XCTAssertThrowsError(try DayOfMonthRecurrenceRuleConstraint.atDayOfMonth(32))

        // month (1-12) ex: 1 is January, 12 is December
        XCTAssertThrowsError(try MonthRecurrenceRuleConstraint.atMonth(0))
        XCTAssertNoThrow(try MonthRecurrenceRuleConstraint.atMonth(1))
        XCTAssertNoThrow(try MonthRecurrenceRuleConstraint.atMonth(12))
        XCTAssertThrowsError(try MonthRecurrenceRuleConstraint.atMonth(13))

        // quarter (1-4)
        XCTAssertThrowsError(try QuarterRecurrenceRuleConstraint.atQuarter(0))
        XCTAssertNoThrow(try QuarterRecurrenceRuleConstraint.atQuarter(1))
        XCTAssertNoThrow(try QuarterRecurrenceRuleConstraint.atQuarter(4))
        XCTAssertThrowsError(try QuarterRecurrenceRuleConstraint.atQuarter(5))

        // year (1970-3000)
        //        XCTAssertThrowsError(try reccurrenceRule.atYear(1969))
        XCTAssertNoThrow(try YearRecurrenceRuleConstraint.atYear(1970))
        XCTAssertNoThrow(try YearRecurrenceRuleConstraint.atYear(3000))
        //        XCTAssertThrowsError(try reccurrenceRule.atYear(3001))
    }

    func testRecurrenceRuleConstraintCreationSetMultipleValues() throws {
        // second (0-59)
        XCTAssertThrowsError(try SecondRecurrenceRuleConstraint.atSeconds([0, 59, -1]))
        XCTAssertNoThrow(try SecondRecurrenceRuleConstraint.atSeconds([0, 59]))
        XCTAssertThrowsError(try SecondRecurrenceRuleConstraint.atSeconds([0, 59, 60]))

        // minute (0-59)
        XCTAssertThrowsError(try MinuteRecurrenceRuleConstraint.atMinutes([0, 59, -1]))
        XCTAssertNoThrow(try MinuteRecurrenceRuleConstraint.atMinutes([0, 59]))
        XCTAssertThrowsError(try MinuteRecurrenceRuleConstraint.atMinutes([0, 59, 60]))

        // hour (0-23)
        XCTAssertThrowsError(try HourRecurrenceRuleConstraint.atHours([0, 23, -1]))
        XCTAssertNoThrow(try HourRecurrenceRuleConstraint.atHours([0, 23]))
        XCTAssertThrowsError(try HourRecurrenceRuleConstraint.atHours([0, 23, 24]))

        // dayOfWeek (1-7) ex: 1 sunday, 7 saturday
        XCTAssertThrowsError(try DayOfWeekRecurrenceRuleConstraint.atDaysOfWeek([1, 7, 0]))
        XCTAssertNoThrow(try DayOfWeekRecurrenceRuleConstraint.atDaysOfWeek([1, 7]))
        XCTAssertThrowsError(try DayOfWeekRecurrenceRuleConstraint.atDaysOfWeek([1, 7, 8]))

        // dayOfMonth (1-31) ex: 1 is the 1st of month, 31 is the 31st of month
        XCTAssertThrowsError(try DayOfMonthRecurrenceRuleConstraint.atDaysOfMonth([1, 31, 0]))
        XCTAssertNoThrow(try DayOfMonthRecurrenceRuleConstraint.atDaysOfMonth([1, 31]))
        XCTAssertThrowsError(try DayOfMonthRecurrenceRuleConstraint.atDaysOfMonth([1, 31, 32]))

        // month (1-12) ex: 1 is January, 12 is December
        XCTAssertThrowsError(try MonthRecurrenceRuleConstraint.atMonths([1, 12, 0]))
        XCTAssertNoThrow(try MonthRecurrenceRuleConstraint.atMonths([1, 12]))
        XCTAssertThrowsError(try MonthRecurrenceRuleConstraint.atMonths([1, 12, 13]))

        // quarter (1-4)
        XCTAssertThrowsError(try QuarterRecurrenceRuleConstraint.atQuarters([1, 4, 0]))
        XCTAssertNoThrow(try QuarterRecurrenceRuleConstraint.atQuarters([1, 4]))
        XCTAssertThrowsError(try QuarterRecurrenceRuleConstraint.atQuarters([1, 4, 5]))

        // year (1970-3000)
        XCTAssertNoThrow(try YearRecurrenceRuleConstraint.atYears([1970, 2019, 3000]))
    }

    func testRecurrenceRuleConstraintCreationRange() throws {
        // second (0-59)
        XCTAssertThrowsError(try SecondRecurrenceRuleConstraint.atSecondsInRange(lowerBound: -1, upperBound: 59))
        XCTAssertNoThrow(try SecondRecurrenceRuleConstraint.atSecondsInRange(lowerBound: 0, upperBound: 59))
        XCTAssertThrowsError(try SecondRecurrenceRuleConstraint.atSecondsInRange(lowerBound: 0, upperBound: 60))

        // minute (0-59)
        XCTAssertThrowsError(try MinuteRecurrenceRuleConstraint.atMinutesInRange(lowerBound: -1, upperBound: 59))
        XCTAssertNoThrow(try MinuteRecurrenceRuleConstraint.atMinutesInRange(lowerBound: 0, upperBound: 59))
        XCTAssertThrowsError(try MinuteRecurrenceRuleConstraint.atMinutesInRange(lowerBound: 0, upperBound: 60))

        // hour (0-23)
        XCTAssertThrowsError(try HourRecurrenceRuleConstraint.atHoursInRange(lowerBound: -1, upperBound: 23))
        XCTAssertNoThrow(try HourRecurrenceRuleConstraint.atHoursInRange(lowerBound: 0, upperBound: 23))
        XCTAssertThrowsError(try HourRecurrenceRuleConstraint.atHoursInRange(lowerBound: 0, upperBound: 24))

        // dayOfWeek (1-7) ex: 1 sunday, 7 saturday
        XCTAssertThrowsError(try DayOfWeekRecurrenceRuleConstraint.atDaysOfWeekInRange(lowerBound: 0, upperBound: 7))
        XCTAssertNoThrow(try DayOfWeekRecurrenceRuleConstraint.atDaysOfWeekInRange(lowerBound: 1, upperBound: 7))
        XCTAssertThrowsError(try DayOfWeekRecurrenceRuleConstraint.atDaysOfWeekInRange(lowerBound: 1, upperBound: 8))

        // dayOfMonth (1-31) ex: 1 is the 1st of month, 31 is the 31st of month
        XCTAssertThrowsError(try DayOfMonthRecurrenceRuleConstraint.atDaysOfMonthInRange(lowerBound: 0, upperBound: 31))
        XCTAssertNoThrow(try DayOfMonthRecurrenceRuleConstraint.atDaysOfMonthInRange(lowerBound: 1, upperBound: 31))
        XCTAssertThrowsError(try DayOfMonthRecurrenceRuleConstraint.atDaysOfMonthInRange(lowerBound: 1, upperBound: 32))

        // month (1-12) ex: 1 is January, 12 is December
        XCTAssertThrowsError(try MonthRecurrenceRuleConstraint.atMonthsInRange(lowerBound: 0, upperBound: 12))
        XCTAssertNoThrow(try MonthRecurrenceRuleConstraint.atMonthsInRange(lowerBound: 1, upperBound: 12))
        XCTAssertThrowsError(try MonthRecurrenceRuleConstraint.atMonthsInRange(lowerBound: 1, upperBound: 13))

        // quarter (1-4)
        XCTAssertThrowsError(try QuarterRecurrenceRuleConstraint.atQuartersInRange(lowerBound: 0, upperBound: 4))
        XCTAssertNoThrow(try QuarterRecurrenceRuleConstraint.atQuartersInRange(lowerBound: 1, upperBound: 4))
        XCTAssertThrowsError(try QuarterRecurrenceRuleConstraint.atQuartersInRange(lowerBound: 1, upperBound: 5))

        // year (1970-3000)
        XCTAssertThrowsError(try YearRecurrenceRuleConstraint.atYearsInRange(lowerBound: 1969, upperBound: 3000))
        XCTAssertNoThrow(try YearRecurrenceRuleConstraint.atYearsInRange(lowerBound: 1970, upperBound: 3000))
        //XCTAssertThrowsError(try reccurrenceRule.atYearsInRange(lowerBound: 1970, upperBound: 3001))
    }

    func testRecurrenceRuleConstraintCreationStep() throws {
        // second (0-59)
        XCTAssertThrowsError(try SecondRecurrenceRuleConstraint.secondStep(0))
        XCTAssertNoThrow(try SecondRecurrenceRuleConstraint.secondStep(1))
        XCTAssertNoThrow(try SecondRecurrenceRuleConstraint.secondStep(59))
        XCTAssertThrowsError(try SecondRecurrenceRuleConstraint.secondStep(60))

        // minute (0-59)
        XCTAssertThrowsError(try MinuteRecurrenceRuleConstraint.minuteStep(0))
        XCTAssertNoThrow(try MinuteRecurrenceRuleConstraint.minuteStep(1))
        XCTAssertNoThrow(try MinuteRecurrenceRuleConstraint.minuteStep(59))
        XCTAssertThrowsError(try MinuteRecurrenceRuleConstraint.minuteStep(60))

        // hour (0-23)
        XCTAssertThrowsError(try HourRecurrenceRuleConstraint.hourStep(0))
        XCTAssertNoThrow(try HourRecurrenceRuleConstraint.hourStep(1))
        XCTAssertNoThrow(try HourRecurrenceRuleConstraint.hourStep(23))
        XCTAssertThrowsError(try HourRecurrenceRuleConstraint.hourStep(24))

        // dayOfWeek (1-7) ex: 1 sunday, 7 saturday
        XCTAssertThrowsError(try DayOfWeekRecurrenceRuleConstraint.dayOfWeekStep(0))
        XCTAssertNoThrow(try DayOfWeekRecurrenceRuleConstraint.dayOfWeekStep(1))
        XCTAssertNoThrow(try DayOfWeekRecurrenceRuleConstraint.dayOfWeekStep(7))
        XCTAssertThrowsError(try DayOfWeekRecurrenceRuleConstraint.dayOfWeekStep(8))

        // dayOfMonth (1-31) ex: 1 is the 1st of month, 31 is the 31st of month
        XCTAssertThrowsError(try DayOfMonthRecurrenceRuleConstraint.dayOfMonthStep(0))
        XCTAssertNoThrow(try DayOfMonthRecurrenceRuleConstraint.dayOfMonthStep(1))
        XCTAssertNoThrow(try DayOfMonthRecurrenceRuleConstraint.dayOfMonthStep(31))
        XCTAssertThrowsError(try DayOfMonthRecurrenceRuleConstraint.dayOfMonthStep(32))

        // month (1-12) ex: 1 is January, 12 is December
        XCTAssertThrowsError(try MonthRecurrenceRuleConstraint.monthStep(0))
        XCTAssertNoThrow(try MonthRecurrenceRuleConstraint.monthStep(1))
        XCTAssertNoThrow(try MonthRecurrenceRuleConstraint.monthStep(12))
        XCTAssertThrowsError(try MonthRecurrenceRuleConstraint.monthStep(53))

        // quarter (1-4)
        XCTAssertThrowsError(try QuarterRecurrenceRuleConstraint.quarterStep(0))
        XCTAssertNoThrow(try QuarterRecurrenceRuleConstraint.quarterStep(1))
        XCTAssertNoThrow(try QuarterRecurrenceRuleConstraint.quarterStep(4))
        XCTAssertThrowsError(try QuarterRecurrenceRuleConstraint.quarterStep(5))

        // year (1970-3000)
        XCTAssertThrowsError(try YearRecurrenceRuleConstraint.yearStep(0))
        XCTAssertNoThrow(try YearRecurrenceRuleConstraint.yearStep(2))
        XCTAssertNoThrow(try YearRecurrenceRuleConstraint.yearStep(1000))
        //        XCTAssertThrowsError(try reccurrenceRule.atYear(3001))
    }
}
