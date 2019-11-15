import XCTest
import NIO
@testable import Jobs

final class RecurrenceRuleTests: XCTestCase {

    func testReccurrenceRuleEvaluationSimple() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        var reccurrenceRule = RecurrenceRule()
        reccurrenceRule.setMonthConstraint(try .atMonth(2))
        reccurrenceRule.setHourConstraint(try .atHour(3))

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

        var reccurrenceRule = RecurrenceRule()
        reccurrenceRule.setMonthConstraint(try .atMonth(2))
        reccurrenceRule.setMinuteConstraint(try .minuteStep(15))

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

        var reccurrenceRule = RecurrenceRule()
        reccurrenceRule.setMonthConstraint(try .atMonth(2))
        reccurrenceRule.setMinuteConstraint(try .minuteStep(22))

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
        //let reccurrenceRuleEST = try RecurrenceRule().atMonth(2).atDayOfMonth(15).atHour(22).atSecond(30).usingTimeZone(timeZoneEST)
        var reccurrenceRuleEST = RecurrenceRule.init(timeZone: timeZoneEST)
        reccurrenceRuleEST.setMonthConstraint(try .atMonth(2))
        reccurrenceRuleEST.setDayOfMonthConstraint(try .atDayOfMonth(15))
        reccurrenceRuleEST.setHourConstraint(try .atHour(22))
        reccurrenceRuleEST.setSecondConstraint(try .atSecond(30))

        XCTAssertEqual(true, try reccurrenceRuleEST.evaluate(date: dateEST))

        // test UTC with EST date
        var reccurrenceRuleUTC = RecurrenceRule.init(timeZone: timeZoneUTC)
        reccurrenceRuleUTC.setMonthConstraint(try .atMonth(2))
        reccurrenceRuleUTC.setDayOfMonthConstraint(try .atDayOfMonth(15))
        reccurrenceRuleUTC.setHourConstraint(try .atHour(22))
        reccurrenceRuleUTC.setSecondConstraint(try .atSecond(30))
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
        let date2 = try date1.nextDate(where: .month, is: 4)
        XCTAssertEqual(dateFormatter.date(from: "2019-04-01T00:00:00")!, date2)
    }

    func testNextDateWhere() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        // Fri, Feb 1, 2019 03:00:00
        let date1 = dateFormatter.date(from: "2019-02-01T03:00:00")!
        /// should reset values less than month to their default values
        let date2 = try date1.nextDate(where: .month, is: 4)
        XCTAssertEqual(dateFormatter.date(from: "2019-04-01T00:00:00")!, date2)

        let date3 = try date2.nextDate(where: .dayOfMonth, is: 26)
        /// should reset values less than dayOfMonth to their default values
        XCTAssertEqual(dateFormatter.date(from: "2019-04-26T00:00:00")!, date3)

        let date4 = try date3.nextDate(where: .minute, is: 33)
        /// should reset values less than dayOfMonth to their default values
        XCTAssertEqual(dateFormatter.date(from: "2019-04-26T00:33:00")!, date4)
    }

    func testResolveNextDateThatSatisfiesRule() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        var reccurrenceRule = RecurrenceRule()
        reccurrenceRule.setMonthConstraint(try .atMonth(4))
        reccurrenceRule.setDayOfMonthConstraint(try .atDayOfMonth(26))
        reccurrenceRule.setMinuteConstraint(try .minuteStep(33))

        // Fri, Feb 1, 2019 03:00:00
        let date1 = dateFormatter.date(from: "2019-02-01T03:00:00")!
        let date2 = try reccurrenceRule.resolveNextDateThatSatisfiesRule(currentDate: date1)
        XCTAssertEqual(dateFormatter.date(from: "2019-04-26T00:00:00")!, date2)

        let date3 = try reccurrenceRule.resolveNextDateThatSatisfiesRule(currentDate: date2)
        XCTAssertEqual(dateFormatter.date(from: "2019-04-26T00:33:00")!, date3)
    }

    func testResolveNextDateThatSatisfiesRuleLeapYear() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        var reccurrenceRule = RecurrenceRule()
        reccurrenceRule.setMonthConstraint(try .atMonth(2))
        reccurrenceRule.setDayOfMonthConstraint(try .atDayOfMonth(29))
        reccurrenceRule.setMinuteConstraint(try .atMinute(25))
        reccurrenceRule.setSecondConstraint(try .atSecond(1))

        // Fri, Feb 1, 2019 03:00:00
        let date1 = dateFormatter.date(from: "2019-02-01T03:00:00")!
        let date2 = try reccurrenceRule.resolveNextDateThatSatisfiesRule(currentDate: date1)
        XCTAssertEqual(dateFormatter.date(from: "2020-02-29T00:25:01")!, date2)
    }

    func testResolveNextDateThatSatisfiesRuleImpossible() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        // impossible as april never has 31 days
        var reccurrenceRule = RecurrenceRule()
        reccurrenceRule.setMonthConstraint(try .atMonth(2))
        reccurrenceRule.setDayOfMonthConstraint(try .atDayOfMonth(31))
        reccurrenceRule.setMinuteConstraint(try .atMinute(25))
        reccurrenceRule.setSecondConstraint(try .atSecond(1))

        // Fri, Jan 1, 2019 00:00:00
        let date1 = dateFormatter.date(from: "2019-01-01T00:00:00")!

        XCTAssertThrowsError(try reccurrenceRule.resolveNextDateThatSatisfiesRule(currentDate: date1))
    }

    func testLastDayOfMonthSimple() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        var reccurrenceRule = RecurrenceRule()
        reccurrenceRule.setDayOfMonthConstraint(try .atLastDayOfMonth())

        // Fri, Jan 1, 2019 00:00:00
        let date1 = dateFormatter.date(from: "2019-01-01T00:00:00")!

        // Thu Jan 31, 2019 18:30:00
        let date2 = dateFormatter.date(from: "2019-01-31T00:00:00")!

        XCTAssertEqual(try reccurrenceRule.resolveNextDateThatSatisfiesRule(currentDate: date1), date2)

        // feb 28, 2019 18:30:00
        let date3 = dateFormatter.date(from: "2019-02-28T00:00:00")!

        XCTAssertEqual(try reccurrenceRule.resolveNextDateThatSatisfiesRule(currentDate: date2), date3)
    }

    func testLastDayOfMonth() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        var reccurrenceRule = RecurrenceRule()
        reccurrenceRule.setDayOfMonthConstraint(try .atLastDayOfMonth())
        reccurrenceRule.setHourConstraint(try .atHour(18))
        reccurrenceRule.setMinuteConstraint(try .atMinute(30))
        reccurrenceRule.setSecondConstraint(try .atSecond(0))

        // Fri, Jan 1, 2019 00:00:00
        let date1 = dateFormatter.date(from: "2019-01-01T18:30:00")!

        // Thu Jan 31, 2019 18:30:00
        let date2 = dateFormatter.date(from: "2019-01-31T18:30:00")!

        XCTAssertEqual(try reccurrenceRule.resolveNextDateThatSatisfiesRule(currentDate: date1), date2)

        // feb 28, 2019 18:30:00
        let date3 = dateFormatter.date(from: "2019-02-28T18:30:00")!

        XCTAssertEqual(try reccurrenceRule.resolveNextDateThatSatisfiesRule(currentDate: date2), date3)
    }

}
