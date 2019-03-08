import XCTest
import NIO
@testable import Jobs

final class JobSchedulerTests: XCTestCase {

    func testRecurrenceRuleCreation() throws {
        let reccurrenceRule = try RecurrenceRule()

        // second (0-59)
        XCTAssertThrowsError(try reccurrenceRule.atSecond(-1))
        XCTAssertNoThrow(try reccurrenceRule.atSecond(0))
        XCTAssertNoThrow(try reccurrenceRule.atSecond(59))
        XCTAssertThrowsError(try reccurrenceRule.atSecond(60))

        // minute (0-59)
        XCTAssertThrowsError(try reccurrenceRule.atMinute(-1))
        XCTAssertNoThrow(try reccurrenceRule.atMinute(0))
        XCTAssertNoThrow(try reccurrenceRule.atMinute(59))
        XCTAssertThrowsError(try reccurrenceRule.atMinute(60))

        // hour (0-23)
        XCTAssertThrowsError(try reccurrenceRule.atHour(-1))
        XCTAssertNoThrow(try reccurrenceRule.atHour(0))
        XCTAssertNoThrow(try reccurrenceRule.atHour(23))
        XCTAssertThrowsError(try reccurrenceRule.atHour(24))

        // dayOfWeek (1-7) ex: 1 sunday, 7 saturday
        XCTAssertThrowsError(try reccurrenceRule.atDayOfWeek(0))
        XCTAssertNoThrow(try reccurrenceRule.atDayOfWeek(1))
        XCTAssertNoThrow(try reccurrenceRule.atDayOfWeek(7))
        XCTAssertThrowsError(try reccurrenceRule.atDayOfWeek(8))

        // dayOfMonth (1-31) ex: 1 is the 1st of month, 31 is the 31st of month
        XCTAssertThrowsError(try reccurrenceRule.atDayOfMonth(0))
        XCTAssertNoThrow(try reccurrenceRule.atDayOfMonth(1))
        XCTAssertNoThrow(try reccurrenceRule.atDayOfMonth(31))
        XCTAssertThrowsError(try reccurrenceRule.atDayOfMonth(32))

        // weekOfMonth (1-5)
        XCTAssertThrowsError(try reccurrenceRule.atWeekOfMonth(0))
        XCTAssertNoThrow(try reccurrenceRule.atWeekOfMonth(1))
        XCTAssertNoThrow(try reccurrenceRule.atWeekOfMonth(5))
        XCTAssertThrowsError(try reccurrenceRule.atWeekOfMonth(6))

        // weekOfYear (1-52)
        XCTAssertThrowsError(try reccurrenceRule.atWeekOfYear(0))
        XCTAssertNoThrow(try reccurrenceRule.atWeekOfYear(1))
        XCTAssertNoThrow(try reccurrenceRule.atWeekOfYear(52))
        XCTAssertThrowsError(try reccurrenceRule.atWeekOfYear(53))

        // month (1-12) ex: 1 is January, 12 is December
        XCTAssertThrowsError(try reccurrenceRule.atMonth(0))
        XCTAssertNoThrow(try reccurrenceRule.atMonth(1))
        XCTAssertNoThrow(try reccurrenceRule.atMonth(12))
        XCTAssertThrowsError(try reccurrenceRule.atMonth(13))

        // quarter (1-4)
        XCTAssertThrowsError(try reccurrenceRule.atQuarter(0))
        XCTAssertNoThrow(try reccurrenceRule.atQuarter(1))
        XCTAssertNoThrow(try reccurrenceRule.atQuarter(4))
        XCTAssertThrowsError(try reccurrenceRule.atQuarter(5))

        // year (1970-3000)
//        XCTAssertThrowsError(try reccurrenceRule.atYear(1969))
        XCTAssertNoThrow(try reccurrenceRule.atYear(1970))
        XCTAssertNoThrow(try reccurrenceRule.atYear(3000))
//        XCTAssertThrowsError(try reccurrenceRule.atYear(3001))
    }

    func testRecurrenceRuleCreationSet() throws {
        let reccurrenceRule = try RecurrenceRule()

        // second (0-59)
        XCTAssertThrowsError(try reccurrenceRule.atSeconds([0, 59, -1]))
        XCTAssertNoThrow(try reccurrenceRule.atSeconds([0, 59]))
        XCTAssertThrowsError(try reccurrenceRule.atSeconds([0, 59, 60]))

        // minute (0-59)
        XCTAssertThrowsError(try reccurrenceRule.atMinutes([0, 59, -1]))
        XCTAssertNoThrow(try reccurrenceRule.atMinutes([0, 59]))
        XCTAssertThrowsError(try reccurrenceRule.atMinutes([0, 59, 60]))

        // hour (0-23)
        XCTAssertThrowsError(try reccurrenceRule.atHours([0, 23, -1]))
        XCTAssertNoThrow(try reccurrenceRule.atHours([0, 23]))
        XCTAssertThrowsError(try reccurrenceRule.atHours([0, 23, 24]))

        // dayOfWeek (1-7) ex: 1 sunday, 7 saturday
        XCTAssertThrowsError(try reccurrenceRule.atDaysOfWeek([1, 7, 0]))
        XCTAssertNoThrow(try reccurrenceRule.atDaysOfWeek([1, 7]))
        XCTAssertThrowsError(try reccurrenceRule.atDaysOfWeek([1, 7, 8]))

        // dayOfMonth (1-31) ex: 1 is the 1st of month, 31 is the 31st of month
        XCTAssertThrowsError(try reccurrenceRule.atDaysOfMonth([1, 31, 0]))
        XCTAssertNoThrow(try reccurrenceRule.atDaysOfMonth([1, 31]))
        XCTAssertThrowsError(try reccurrenceRule.atDaysOfMonth([1, 31, 32]))

        // weekOfMonth (1-5)
        XCTAssertThrowsError(try reccurrenceRule.atWeeksOfMonth([1, 5, 0]))
        XCTAssertNoThrow(try reccurrenceRule.atWeeksOfMonth([1, 5]))
        XCTAssertThrowsError(try reccurrenceRule.atWeeksOfMonth([1, 5, 6]))

        // weekOfYear (1-52)
        XCTAssertThrowsError(try reccurrenceRule.atWeeksOfYear([1, 52, 0]))
        XCTAssertNoThrow(try reccurrenceRule.atWeeksOfYear([1, 52]))
        XCTAssertThrowsError(try reccurrenceRule.atWeeksOfYear([1, 52, 53]))

        // month (1-12) ex: 1 is January, 12 is December
        XCTAssertThrowsError(try reccurrenceRule.atMonths([1, 12, 0]))
        XCTAssertNoThrow(try reccurrenceRule.atMonths([1, 12]))
        XCTAssertThrowsError(try reccurrenceRule.atMonths([1, 12, 13]))

        // quarter (1-4)
        XCTAssertThrowsError(try reccurrenceRule.atQuarters([1, 4, 0]))
        XCTAssertNoThrow(try reccurrenceRule.atQuarters([1, 4]))
        XCTAssertThrowsError(try reccurrenceRule.atQuarters([1, 4, 5]))

        // year (1970-3000)
        //        XCTAssertThrowsError(try reccurrenceRule.atYear(1969))
        XCTAssertNoThrow(try reccurrenceRule.atYears([1970, 2019, 3000]))
        //        XCTAssertThrowsError(try reccurrenceRule.atYear(3001))
    }

    func testRecurrenceRuleCreationStep() throws {
        let reccurrenceRule = try RecurrenceRule()

        // second (0-59)
        XCTAssertThrowsError(try reccurrenceRule.every(.seconds(-1)))
        XCTAssertNoThrow(try reccurrenceRule.every(.seconds(0)))
        XCTAssertNoThrow(try reccurrenceRule.every(.seconds(59)))
        XCTAssertThrowsError(try reccurrenceRule.every(.seconds(60)))

        // minute (0-59)
        XCTAssertThrowsError(try reccurrenceRule.every(.minutes(-1)))
        XCTAssertNoThrow(try reccurrenceRule.every(.minutes(0)))
        XCTAssertNoThrow(try reccurrenceRule.every(.minutes(59)))
        XCTAssertThrowsError(try reccurrenceRule.every(.minutes(60)))

        // hour (0-23)
        XCTAssertThrowsError(try reccurrenceRule.every(.hours(-1)))
        XCTAssertNoThrow(try reccurrenceRule.every(.hours(0)))
        XCTAssertNoThrow(try reccurrenceRule.every(.hours(23)))
        XCTAssertThrowsError(try reccurrenceRule.every(.hours(24)))

        // dayOfWeek (1-7) ex: 1 sunday, 7 saturday
        XCTAssertThrowsError(try reccurrenceRule.every(.minutes(-1)))
        XCTAssertNoThrow(try reccurrenceRule.every(.minutes(-1)))
        XCTAssertNoThrow(try reccurrenceRule.every(.minutes(-1)))
        XCTAssertThrowsError(try reccurrenceRule.every(.minutes(-1)))

        // dayOfMonth (1-31) ex: 1 is the 1st of month, 31 is the 31st of month
        XCTAssertThrowsError(try reccurrenceRule.every(.days(0)))
        XCTAssertNoThrow(try reccurrenceRule.every(.days(1)))
        XCTAssertNoThrow(try reccurrenceRule.every(.days(31)))
        XCTAssertThrowsError(try reccurrenceRule.every(.days(32)))

        // weekOfMonth (1-5)
        XCTAssertThrowsError(try reccurrenceRule.every(.weeks(0)))
        XCTAssertNoThrow(try reccurrenceRule.every(.weeks(1)))
        XCTAssertNoThrow(try reccurrenceRule.every(.weeks(5)))
        XCTAssertThrowsError(try reccurrenceRule.every(.weeks(6)))

        // weekOfYear (1-52)
//        XCTAssertThrowsError(try reccurrenceRule.every(.weeks(-1)))
//        XCTAssertNoThrow(try reccurrenceRule.every(.weeks(-1)))
//        XCTAssertNoThrow(try reccurrenceRule.every(.weeks(-1)))
//        XCTAssertThrowsError(try reccurrenceRule.every(.weeks(-1)))

        // month (1-12) ex: 1 is January, 12 is December
        XCTAssertThrowsError(try reccurrenceRule.every(.months(-1)))
        XCTAssertNoThrow(try reccurrenceRule.every(.months(-1)))
        XCTAssertNoThrow(try reccurrenceRule.every(.months(-1)))
        XCTAssertThrowsError(try reccurrenceRule.every(.months(-1)))

        // quarter (1-4)
//        XCTAssertThrowsError(try reccurrenceRule.every(.quarters(0)))
//        XCTAssertNoThrow(try reccurrenceRule.every(.quarters(-1)))
//        XCTAssertNoThrow(try reccurrenceRule.every(.quarters(-1)))
//        XCTAssertThrowsError(try reccurrenceRule.every(.quarters(-1)))

        // year (1970-3000)
        //        XCTAssertThrowsError(try reccurrenceRule.atYear(1969))
        XCTAssertNoThrow(try reccurrenceRule.every(.years(2)))
        XCTAssertNoThrow(try reccurrenceRule.every(.years(1000)))
        //        XCTAssertThrowsError(try reccurrenceRule.atYear(3001))
    }

    func testReccurrenceRuleEvaluationSimple() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        let reccurrenceRule = try RecurrenceRule().atMonth(2).atHour(3)

        // Fri, Feb 1, 2019 03:00:00
        let date1 = dateFormatter.date(from: "2019-02-01T03:00:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date1))

        // Fri, Feb 1, 2019 03:00:01
        let date2 = dateFormatter.date(from: "2019-02-01T03:00:01")!
        XCTAssertEqual(false, try reccurrenceRule.evaluate(date: date2))

        // Fri, Feb 1, 2019 04:00:00
        let date3 = dateFormatter.date(from: "2019-02-01T04:00:00")!
        XCTAssertEqual(false, try reccurrenceRule.evaluate(date: date3))
    }

    func testReccurrenceRuleEvaluationStepSimple() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        let reccurrenceRule = try RecurrenceRule().atMonth(2).every(.minutes(15))

        // Fri, Feb 1, 2019 03:00:00
        let date1 = dateFormatter.date(from: "2019-02-01T03:00:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date1))

        // Fri, Feb 1, 2019 03:15:00
        let date2 = dateFormatter.date(from: "2019-02-01T03:15:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date2))

        // Fri, Feb 1, 2019 03:30:00
        let date3 = dateFormatter.date(from: "2019-02-01T03:30:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date3))

        // Fri, Feb 1, 2019 03:45:00
        let date4 = dateFormatter.date(from: "2019-02-01T03:45:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date4))

        // Fri, Feb 1, 2019 04:45:00
        let date5 = dateFormatter.date(from: "2019-02-01T04:00:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date5))
    }

    func testReccurrenceRuleEvaluationStepNotDivisible() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        let reccurrenceRule = try RecurrenceRule().atMonth(2).every(.minutes(22))

        // Fri, Feb 1, 2019 03:00:00
        let date1 = dateFormatter.date(from: "2019-02-01T03:00:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date1))

        // Fri, Feb 1, 2019 03:22:00
        let date2 = dateFormatter.date(from: "2019-02-01T03:22:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date2))

        // Fri, Feb 1, 2019 03:44:00
        let date3 = dateFormatter.date(from: "2019-02-01T03:44:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date3))

        // Fri, Feb 1, 2019 04:00:00
        let date4 = dateFormatter.date(from: "2019-02-01T04:00:00")!
        XCTAssertEqual(true, try reccurrenceRule.evaluate(date: date4))

        // Fri, Feb 1, 2019 04:04:00
        // should evaluate to false beacuse the minute step constraint is multiples within hour
        // ex step constraint of 22 minutes [3:00, 3:22, 3:44, 4:00, 4:22, ...]
        let date5 = dateFormatter.date(from: "2019-02-01T04:06:00")!
        XCTAssertEqual(false, try reccurrenceRule.evaluate(date: date5))

    }

    func testReccurrenceRuleEvaluationTimezone() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        guard let timeZoneEST = TimeZone.init(abbreviation: "EST") else {
            XCTFail()
            return
        }

        guard let timeZoneUTC = TimeZone.init(abbreviation: "UTC") else {
            XCTFail()
            return
        }

        // Fri, Feb 1, 2019 03:00:00 EST
        dateFormatter.timeZone = timeZoneEST
        let dateEST = dateFormatter.date(from: "2019-02-15T22:00:30")!

        // test EST
        let reccurrenceRuleEST = try RecurrenceRule().atMonth(2).atDayOfMonth(15).atHour(22).atSecond(30).usingTimeZone(timeZoneEST)
        XCTAssertEqual(true, try reccurrenceRuleEST.evaluate(date: dateEST))

        // test UTC with EST date
        let reccurrenceRuleUTC = try RecurrenceRule().atMonth(2).atDayOfMonth(15).atHour(22).atSecond(30).usingTimeZone(timeZoneUTC)
        XCTAssertEqual(false, try reccurrenceRuleUTC.evaluate(date: dateEST))

        // test UTC with UTC date
        // Fri, Feb 1, 2019 03:00:00 UTC
        dateFormatter.timeZone = timeZoneUTC
        let dateUTC = dateFormatter.date(from: "2019-02-15T22:00:30")!
        XCTAssertEqual(true, try reccurrenceRuleUTC.evaluate(date: dateUTC))
    }

    func testNextDateWhereSimple() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        // Fri, Feb 1, 2019 03:00:00
        let date1 = dateFormatter.date(from: "2019-02-01T03:00:00")!
        /// should reset values less than month to their default values
        let date2 = try date1.nextDate(where: .month, is: 4)!
        XCTAssertEqual(dateFormatter.date(from: "2019-04-01T00:00:00")!, date2)
    }

    func testNextDateWhere() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        // Fri, Feb 1, 2019 03:00:00
        let date1 = dateFormatter.date(from: "2019-02-01T03:00:00")!
        /// should reset values less than month to their default values
        let date2 = try date1.nextDate(where: .month, is: 4)!
        XCTAssertEqual(dateFormatter.date(from: "2019-04-01T00:00:00")!, date2)

        let date3 = try date2.nextDate(where: .dayOfMonth, is: 26)!
        /// should reset values less than dayOfMonth to their default values
        XCTAssertEqual(dateFormatter.date(from: "2019-04-26T00:00:00")!, date3)

        let date4 = try date3.nextDate(where: .minute, is: 33)!
        /// should reset values less than dayOfMonth to their default values
        XCTAssertEqual(dateFormatter.date(from: "2019-04-26T00:33:00")!, date4)
    }

    func testResolveNextDateThatSatisfiesRule() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        let reccurrenceRule = try RecurrenceRule().atMonth(4).atDayOfMonth(26).every(.minutes(33))

        // Fri, Feb 1, 2019 03:00:00
        let date1 = dateFormatter.date(from: "2019-02-01T03:00:00")!
        let date2 = try reccurrenceRule.resolveNextDateThatSatisfiesRule(date: date1)
        XCTAssertEqual(dateFormatter.date(from: "2019-04-26T00:00:00")!, date2)

        let date3 = try reccurrenceRule.resolveNextDateThatSatisfiesRule(date: date2)
        XCTAssertEqual(dateFormatter.date(from: "2019-04-26T00:33:00")!, date3)
    }

    func testResolveNextDateThatSatisfiesRuleLeapYear() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        let reccurrenceRule = try RecurrenceRule().atMonth(2).atDayOfMonth(29).atMinute(25).atSecond(1)

        // Fri, Feb 1, 2019 03:00:00
        let date1 = dateFormatter.date(from: "2019-02-01T03:00:00")!
        let date2 = try reccurrenceRule.resolveNextDateThatSatisfiesRule(date: date1)
        XCTAssertEqual(dateFormatter.date(from: "2020-02-29T00:25:01")!, date2)
    }

    static var allTests = [
        ("testReccurrenceRuleEvaluationSimple", testReccurrenceRuleEvaluationSimple),
        ("testReccurrenceRuleEvaluationStepSimple", testReccurrenceRuleEvaluationStepSimple),
        ("testReccurrenceRuleStepEvaluationNotDivisible", testReccurrenceRuleEvaluationStepNotDivisible),
        ("testNextDateWhere", testNextDateWhere),
        ("testResolveNextDateThatSatisfiesRule", testResolveNextDateThatSatisfiesRule),
        ("testResolveNextDateThatSatisfiesRuleLeapYear", testResolveNextDateThatSatisfiesRuleLeapYear)
    ]
}
