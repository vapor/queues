//
//  ReccurrenceRule.swift
//
//  Created by Reid Nantes on 2019-01-26.
//

import Foundation

enum RecurrenceRuleError: Error {
    case yearNotGreaterThan1970
    case quarterNotBetweenZeroAnd3
    case monthNotBetweenOneAndTwelve
    case weekOfYearNotBetweenOneAndFiftyTwo
    case weekOfMonthNotBetweenOneAndFive
    case dayOfMonthNotBetweenOneAndThirtyOne
    case dayOfWeekNotBetweenZeroAndSix
    case hourNotBetweenZeroAndTwentyThree
    case minuteNotBetweenZeroAndFiftyNine
    case secondNotBetweenZeroAndFiftyNine

    case lowerBoundGreaterThanUpperBound

    case noSetConstraintForRecurrenceRuleTimeUnit
    case couldNotResolveDateComponentValueFromRecurrenceRuleTimeUnit
}

public class RecurrenceRule {
    let referenceDate: Date

    // year (>=1970)
    // quarter (1-4)
    // month (1-12) ex: 1 is january, 12 is December
    // weekOfYear (1-52)
    // weekOfMonth (1-5)
    // dayOfMonth (1-31) ex: 1 is the 1st of month, 31 is the 31st of month
    // dayOfWeek (1-7) ex: 1 sunday, 7 saturday
    // hour (0-23)
    // minute (0-59)
    // second (0-59)
    let yearConstraint = RecurrenceRuleConstraint.init(validLowerBound: 1970, validUpperBound: nil)
    let quarterConstraint = RecurrenceRuleConstraint.init(validLowerBound: 1, validUpperBound: 4)
    let monthConstraint = RecurrenceRuleConstraint.init(validLowerBound: 1, validUpperBound: 12)
    let weekOfYearConstraint = RecurrenceRuleConstraint.init(validLowerBound: 1, validUpperBound: 52)
    let weekOfMonthConstraint = RecurrenceRuleConstraint.init(validLowerBound: 1, validUpperBound: 5)
    let dayOfMonthConstraint = RecurrenceRuleConstraint.init(validLowerBound: 1, validUpperBound: 31)
    let dayOfWeekConstraint = RecurrenceRuleConstraint.init(validLowerBound: 1, validUpperBound: 7)
    let hourConstraint = RecurrenceRuleConstraint.init(validLowerBound: 0, validUpperBound: 23)
    let minuteConstraint = RecurrenceRuleConstraint.init(validLowerBound: 0, validUpperBound: 59)
    let secondConstraint = RecurrenceRuleConstraint.init(validLowerBound: 0, validUpperBound: 59)

    public init() {
        self.referenceDate = Date()
    }



    func resolveConstraint(_ ruleTimeUnit: RecurrenceRuleTimeUnit) -> RecurrenceRuleConstraint {
        switch ruleTimeUnit {
        case .second:
            return self.secondConstraint
        case .minute:
            return self.minuteConstraint
        case .hour:
            return self.hourConstraint
        case .dayOfWeek:
            return self.dayOfWeekConstraint
        case .dayOfMonth:
            return self.dayOfMonthConstraint
        case .weekOfMonth:
            return self.weekOfMonthConstraint
        case .weekOfYear:
            return self.weekOfYearConstraint
        case .month:
            return self.monthConstraint
        case .quarter:
            return self.quarterConstraint
        case .year:
            return self.yearConstraint
        }
    }


    // step
    public func every(_ timeAmount: ScheduleTimeAmount) throws -> Self {
        switch timeAmount.timeUnit {
        case .second:
            try secondConstraint.setStep(timeAmount.amount)
        case .minute:
            try minuteConstraint.setStep(timeAmount.amount)
        case .hour:
            try hourConstraint.setStep(timeAmount.amount)
        case .day:
            try dayOfWeekConstraint.setStep(timeAmount.amount)
        case .week:
            try weekOfMonthConstraint.setStep(timeAmount.amount)
        case .month:
            try monthConstraint.setStep(timeAmount.amount)
        case .year:
            try yearConstraint.setStep(timeAmount.amount)
        }

        return self
    }

    // set
    public func atSecond(_ second: Int) throws -> Self {
        try secondConstraint.addToSet(second)
        return self
    }

    public func atMinute(_ minute: Int) throws -> Self {
        try minuteConstraint.addToSet(minute)
        return self
    }

    public func atHour(_ hour: Int) throws -> Self {
        try hourConstraint.addToSet(hour)
        return self
    }

    public func atDayOfWeek(_ dayOfWeek: Int) throws -> Self {
        try dayOfWeekConstraint.addToSet(dayOfWeek)
        return self
    }

    public func atDayOfMonth(_ dayOfMonth: Int) throws -> Self {
        try dayOfMonthConstraint.addToSet(dayOfMonth)
        return self
    }

    public func atMonth(_ month: Int) throws -> Self {
        try monthConstraint.addToSet(month)
        return self
    }

    public func atYear(_ year: Int) throws -> Self {
        try yearConstraint.addToSet(year)
        return self
    }


    // arrays
    public func atSeconds(_ seconds: [Int]) throws -> Self {
        try secondConstraint.addToSet(seconds)
        return self
    }

    public func atMinutes(_ minutes: [Int]) throws -> Self {
        try minuteConstraint.addToSet(minutes)
        return self
    }

    public func atHours(_ hours: [Int]) throws -> Self {
        try hourConstraint.addToSet(hours)
        return self
    }

    public func atDaysOfWeek(_ daysOfWeek: [Int]) throws -> Self {
        try dayOfWeekConstraint.addToSet(daysOfWeek)
        return self
    }

    public func atDaysOfMonth(_ daysOfMonth: [Int]) throws -> Self {
        try dayOfMonthConstraint.addToSet(daysOfMonth)
        return self
    }

    public func atMonths(_ months: [Int]) throws -> Self {
       try monthConstraint.addToSet(months)
        return self
    }

    public func atYears(_ years: [Int]) throws -> Self {
        try yearConstraint.addToSet(years)
        return self
    }

    // ranges
    public func whenSecondInRange(lowerBound: Int, upperBound: Int) throws -> Self {
        try secondConstraint.createRange(lowerBound: lowerBound, upperBound: upperBound)

        return self
    }

    public func whenMinuteInRange(lowerBound: Int, upperBound: Int) throws -> Self {
        try minuteConstraint.createRange(lowerBound: lowerBound, upperBound: upperBound)

        return self
    }

    public func whenHourInRange(lowerBound: Int, upperBound: Int) throws -> Self {
        try hourConstraint.createRange(lowerBound: lowerBound, upperBound: upperBound)

        return self
    }

    public func whenDayOfWeekInRange(lowerBound: Int, upperBound: Int) throws -> Self {
        try dayOfWeekConstraint.createRange(lowerBound: lowerBound, upperBound: upperBound)

        return self
    }

    public func whenDayOfMonthInRange(lowerBound: Int, upperBound: Int) throws -> Self {
        try dayOfMonthConstraint.createRange(lowerBound: lowerBound, upperBound: upperBound)

        return self
    }

    
    public func whenMonthInRange(lowerBound: Int, upperBound: Int) throws -> Self {
        try monthConstraint.createRange(lowerBound: lowerBound, upperBound: upperBound)

        return self
    }

    public func whenQuarterInRange(lowerBound: Int, upperBound: Int) throws -> Self {
        try quarterConstraint.createRange(lowerBound: lowerBound, upperBound: upperBound)

        return self
    }

    public func whenYearInRange(lowerBound: Int, upperBound: Int) throws -> Self {
        try yearConstraint.createRange(lowerBound: lowerBound, upperBound: upperBound)

        return self
    }

    public func evaluate(date: Date) throws -> Bool {
        var ruleEvaluationState = EvaluationState.noComparisonAttempted

        try RecurrenceRuleTimeUnit.allCases.forEach {
            if ruleEvaluationState == .failed {
                // break enum iteraton
                return
            }

            let constraint = resolveConstraint($0)
            guard let dateComponentValue = date.resolveDateComponentValue(for: $0) else {
                throw RecurrenceRuleError.couldNotResolveDateComponentValueFromRecurrenceRuleTimeUnit
            }

            let constraintEvalutionState = constraint.evaluate(dateComponentValue)
            if constraintEvalutionState != .noComparisonAttempted {
                ruleEvaluationState = constraintEvalutionState
            } else {
                /// If second, minute, hour, dayOfMonth or month constraints are not set
                /// they must be at their default values to avoid rule passing on every second
                if $0 == .second && dateComponentValue != 0 {
                    ruleEvaluationState = .failed
                } else if $0 == .minute && dateComponentValue != 0 {
                    ruleEvaluationState = .failed
                } else if $0 == .hour && dateComponentValue != 0 {
                    ruleEvaluationState = .failed
                } else if $0 == .dayOfMonth && dateComponentValue != 1 {
                    ruleEvaluationState = .failed
                } else if $0 == .month && dateComponentValue != 1 {
                    ruleEvaluationState = .failed
                }
            }

        }

        if ruleEvaluationState == .passing {
            return true
        } else {
            return false
        }
    }
    
}
