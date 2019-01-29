//
//  ReccurrenceRules.swift
//  App
//
//  Created by Reid Nantes on 2019-01-26.
//

import Foundation

enum RecurrenceRuleError: Error {
    case yearNotGreaterThan1970
    case monthNotBetweenOneAndTwelve
    case dayOfMonthNotBetweenOneAndThirtyOne
    case dayOfWeekNotBetweenZeroAndSix
    case hourNotBetweenZeroAndTwentyThree
    case minuteNotBetweenZeroAndFiftyNine
    case secondNotBetweenZeroAndFiftyNine

    case lowerBoundGreaterThanUpperBound
}

public class RecurrenceRule {
    let referenceDate: Date

    // single or list of values
    var years = Set<Int>()
    var months = Set<Int>()
    var daysOfMonth = Set<Int>()
    var daysOfWeek = Set<Int>()
    var hours =  Set<Int>()
    var minutes = Set<Int>()
    var seconds = Set<Int>()

    // range Values
    var yearRange: ClosedRange<Int>?
    var monthRange: ClosedRange<Int>?
    var dayOfMonthRange: ClosedRange<Int>?
    var dayOfWeekRange: ClosedRange<Int>?
    var hourRange: ClosedRange<Int>?
    var minuteRange: ClosedRange<Int>?
    var secondRange: ClosedRange<Int>?

    // step values
    var yearStep: Int? = nil
    var monthStep: Int? = nil
    var weekStep: Int? = nil
    var dayStep: Int? = nil
    var dayOfMonthStep: Int? = nil
    var dayOfWeekStep: Int? = nil
    var hourStep: Int? = nil
    var minuteStep: Int? = nil
    var secondStep: Int? = nil

    
    // year (>=1970)
    // month (1-12) ex: 1 is january, 12 is December
    // dayOfMonth (1-31) ex: 1 is the 1st of month, 31 is the 31st of month
    // dayOfWeek (0-6) ex: 0 sunday, 6 saturday
    // hour: Int (0-23)
    // minute: Int (0-59)
    // second: Int (0-59)

    // to do
    // weekOfYear (0-53) ex: 42 is the 43rd month of the year
    // weekOfMonth (0-4) ex: 0 is the 1st week of the month

    public init() {
        self.referenceDate = Date()
    }


    func testValueIsSetOrWithinRange(set: Set<Int>, range: ClosedRange<Int>?, dateComponentValue: Int) -> EvaluationState {
        if set.count > 0 {
            if set.contains(dateComponentValue) {
                return EvaluationState.passing
            } else {
                return EvaluationState.failed
            }
        }

        if let range = range {
            if range.contains(dateComponentValue) {
                return EvaluationState.passing
            } else {
                return EvaluationState.failed
            }
        }

        return EvaluationState.noComparisonAttempted
    }

    public func doesSatisfyRule(_ ruleTimeUnit: RecurrenceRuleTimeUnit, currentDate: Date) throws -> EvaluationState {
        switch ruleTimeUnit {
        case .second:
            guard let dateComponentValue = currentDate.second() else {
                return EvaluationState.failed
            }
            return testValueIsSetOrWithinRange(set: seconds, range: secondRange, dateComponentValue: dateComponentValue)
        case .minute:
            guard let dateComponentValue = currentDate.minute() else {
                return EvaluationState.failed
            }
            return testValueIsSetOrWithinRange(set: minutes, range: minuteRange, dateComponentValue: dateComponentValue)
        case .hour:
            guard let dateComponentValue = currentDate.hour() else {
                return EvaluationState.failed
            }
            return testValueIsSetOrWithinRange(set: hours, range: hourRange, dateComponentValue: dateComponentValue)
        case .dayOfWeek:
            guard let dateComponentValue = currentDate.dayOfWeek() else {
                return EvaluationState.failed
            }
            return testValueIsSetOrWithinRange(set: daysOfWeek, range: dayOfWeekRange, dateComponentValue: dateComponentValue)
        case .dayOfMonth:
            guard let dateComponentValue = currentDate.dayOfMonth() else {
                return EvaluationState.failed
            }
            return testValueIsSetOrWithinRange(set: daysOfMonth, range: dayOfMonthRange, dateComponentValue: dateComponentValue)
        case .month:
            guard let dateComponentValue = currentDate.month() else {
                return EvaluationState.failed
            }
            return testValueIsSetOrWithinRange(set: months, range: monthRange, dateComponentValue: dateComponentValue)
        case .year:
            guard let dateComponentValue = currentDate.year() else {
                return EvaluationState.failed
            }
            return testValueIsSetOrWithinRange(set: years, range: yearRange, dateComponentValue: dateComponentValue)
        }
    }

    public func every(_ timeAmount: ScheduleTimeAmount) -> Self {
        switch timeAmount.timeUnit {
        case .second:
            self.secondStep = timeAmount.amount
        case .minute:
            self.minuteStep = timeAmount.amount
        case .hour:
            self.hourStep = timeAmount.amount
        case .day:
            self.dayStep = timeAmount.amount
        case .week:
            self.weekStep = timeAmount.amount
        case .month:
            self.monthStep = timeAmount.amount
        case .year:
            self.yearStep = timeAmount.amount
        }

        return self
    }

    internal func addToSet(ruleTimeUnit: RecurrenceRuleTimeUnit, amount: Int) throws {
        let validate = resolveValidator(for: ruleTimeUnit)
        try validate(amount)

        switch ruleTimeUnit {
        case .second:
            self.seconds.insert(amount)
        case .minute:
            self.minutes.insert(amount)
        case .hour:
            self.hours.insert(amount)
        case .dayOfWeek:
            self.daysOfWeek.insert(amount)
        case .dayOfMonth:
            self.daysOfMonth.insert(amount)
        case .month:
            self.months.insert(amount)
        case .year:
            self.years.insert(amount)
        }
    }

    public func atSecond(_ second: Int) throws -> Self {
        try addToSet(ruleTimeUnit: .second, amount: second)

        return self
    }

    public func atMinute(_ minute: Int) throws -> Self {
        try addToSet(ruleTimeUnit: .minute, amount: minute)

        return self
    }

    public func atHour(_ hour: Int) throws -> Self {
        try addToSet(ruleTimeUnit: .hour, amount: hour)

        return self
    }

    public func atDayOfWeek(_ dayOfWeek: Int) throws -> Self {
        try addToSet(ruleTimeUnit: .dayOfWeek, amount: dayOfWeek)

        return self
    }

    public func atDayOfMonth(_ dayOfMonth: Int) throws -> Self {
        try addToSet(ruleTimeUnit: .dayOfMonth, amount: dayOfMonth)

        return self
    }

    public func atMonth(_ month: Int) throws -> Self {
        try addToSet(ruleTimeUnit: .month, amount: month)

        return self
    }

    public func atYear(_ year: Int) throws -> Self {
        try addToSet(ruleTimeUnit: .year, amount: year)

        return self
    }


    // arrays
    internal func addToSet(ruleTimeUnit: RecurrenceRuleTimeUnit, amounts: [Int]) throws {
        let validate = resolveValidator(for: ruleTimeUnit)

        // validate all amounts
        for amount in amounts {
            try validate(amount)
        }

        for amount in amounts {
            switch ruleTimeUnit {
            case .second:
                self.seconds.insert(amount)
            case .minute:
                self.minutes.insert(amount)
            case .hour:
                self.hours.insert(amount)
            case .dayOfWeek:
                self.daysOfWeek.insert(amount)
            case .dayOfMonth:
                self.daysOfMonth.insert(amount)
            case .month:
                self.months.insert(amount)
            case .year:
                self.years.insert(amount)
            }
        }
    }

    public func atSeconds(_ seconds: [Int]) throws -> Self {
        try addToSet(ruleTimeUnit: .second, amounts: seconds)

        return self
    }

    public func atMinutes(_ minutes: [Int]) throws -> Self {
        try addToSet(ruleTimeUnit: .minute, amounts: minutes)

        return self
    }

    public func atHours(_ hours: [Int]) throws -> Self {
        try addToSet(ruleTimeUnit: .hour, amounts: hours)

        return self
    }

    public func atDaysOfWeek(_ daysOfWeek: [Int]) throws -> Self {
        try addToSet(ruleTimeUnit: .dayOfWeek, amounts: daysOfWeek)

        return self
    }

    public func atDaysOfMonth(_ daysOfMonth: [Int]) throws -> Self {
        try addToSet(ruleTimeUnit: .dayOfMonth, amounts: daysOfMonth)

        return self
    }

    public func atMonths(_ months: [Int]) throws -> Self {
       try addToSet(ruleTimeUnit: .month, amounts: months)

        return self
    }

    public func atYear(_ years: [Int]) throws -> Self {
        try addToSet(ruleTimeUnit: .year, amounts: years)

        return self
    }

    // ranges
    internal func createRange(ruleTimeUnit: RecurrenceRuleTimeUnit, lowerBound: Int, upperBound: Int) throws {
        if lowerBound > upperBound { throw RecurrenceRuleError.lowerBoundGreaterThanUpperBound }

        let validate = resolveValidator(for: ruleTimeUnit)
        try validate(lowerBound)
        try validate(upperBound)

        switch ruleTimeUnit {
        case .second:
            self.secondRange = lowerBound...upperBound
        case .minute:
            self.minuteRange = lowerBound...upperBound
        case .hour:
            self.hourRange = lowerBound...upperBound
        case .dayOfWeek:
            self.dayOfWeekRange = lowerBound...upperBound
        case .dayOfMonth:
            self.dayOfMonthRange = lowerBound...upperBound
        case .month:
            self.monthRange = lowerBound...upperBound
        case .year:
            self.yearRange = lowerBound...upperBound
        }
    }

    public func whenSecondInRange(lowerBound: Int, upperBound: Int) throws -> Self {
        try createRange(ruleTimeUnit: .second, lowerBound: lowerBound, upperBound: upperBound)

        return self
    }

    public func whenMinuteInRange(lowerBound: Int, upperBound: Int) throws -> Self {
        try createRange(ruleTimeUnit: .minute, lowerBound: lowerBound, upperBound: upperBound)

        return self
    }

    public func whenHourInRange(lowerBound: Int, upperBound: Int) throws -> Self {
        try createRange(ruleTimeUnit: .hour, lowerBound: lowerBound, upperBound: upperBound)

        return self
    }

    public func whenDayOfWeekInRange(lowerBound: Int, upperBound: Int) throws -> Self {
        try createRange(ruleTimeUnit: .dayOfMonth, lowerBound: lowerBound, upperBound: upperBound)

        return self
    }

    public func whenDayOfMonthInRange(lowerBound: Int, upperBound: Int) throws -> Self {
        try createRange(ruleTimeUnit: .dayOfMonth, lowerBound: lowerBound, upperBound: upperBound)

        return self
    }

    
    public func whenMonthInRange(lowerBound: Int, upperBound: Int) throws -> Self {
        try createRange(ruleTimeUnit: .month, lowerBound: lowerBound, upperBound: upperBound)

        return self
    }

    public func whenYearInRange(lowerBound: Int, upperBound: Int) throws -> Self {
        try createRange(ruleTimeUnit: .year, lowerBound: lowerBound, upperBound: upperBound)

        return self
    }


    // validators
    func resolveValidator(for ruleTimeUnit: RecurrenceRuleTimeUnit) -> (Int) throws -> Void {
        switch ruleTimeUnit {
        case .second:
            return validateSecond
        case .minute:
            return validateMinute
        case .hour:
            return validateHour
        case .dayOfWeek:
            return validateDayOfWeek
        case .dayOfMonth:
            return validateDayOfMonth
        case .month:
           return validateMonth
        case .year:
            return validateYear
        }
    }

    func validateSecond(_ second: Int) throws {
        if second >= 0 && second <= 59 {
            return
        }

        throw RecurrenceRuleError.yearNotGreaterThan1970
    }

    func validateMinute(_ minute: Int) throws {
        if minute >= 0 && minute <= 59 {
            return
        }

        throw RecurrenceRuleError.minuteNotBetweenZeroAndFiftyNine
    }

    func validateHour(_ hour: Int) throws {
        if hour >= 0 && hour <= 23 {
            return
        }

        throw RecurrenceRuleError.hourNotBetweenZeroAndTwentyThree
    }

    func validateDayOfWeek(_ dayOfWeek: Int) throws {
        if dayOfWeek >= 0 && dayOfWeek <= 6  {
            return
        }

        throw RecurrenceRuleError.dayOfWeekNotBetweenZeroAndSix
    }

    func validateDayOfMonth(_ dayOfMonth: Int) throws {
        if dayOfMonth >= 0 && dayOfMonth <= 31 {
            return
        }

        throw RecurrenceRuleError.dayOfMonthNotBetweenOneAndThirtyOne
    }

    func validateMonth(_ month: Int) throws {
        if month >= 0 && month <= 23 {
            return
        }

         throw RecurrenceRuleError.monthNotBetweenOneAndTwelve
    }

    func validateYear(_ year: Int) throws {
        if year >= 1970 {
            return
        }

         throw RecurrenceRuleError.yearNotGreaterThan1970
    }
    
}
