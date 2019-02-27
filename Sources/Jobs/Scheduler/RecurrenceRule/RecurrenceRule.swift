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
    case noConstraintsSetForRecurrenceRule

    case coundNotResolveNextInstanceWithin1000Years
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

    private func resolveLowestCadence() -> RecurrenceRuleTimeUnit {
        if secondConstraint.isConstraintActive {
            return .second
        } else if minuteConstraint.isConstraintActive {
            return .minute
        } else if hourConstraint.isConstraintActive {
            return .hour
        } else if dayOfMonthConstraint.isConstraintActive {
            return .dayOfMonth
        } else if monthConstraint.isConstraintActive {
            return .month
        } else {
            return .year
        }
    }

    private func resolveCadenceLevel(_ ruleTimeUnit: RecurrenceRuleTimeUnit) -> Int {
        switch ruleTimeUnit {
        case .second:
            return 0
        case .minute:
            return 1
        case .hour:
            return 2
        case .dayOfMonth:
            return 3
        case .month:
            return 4
        default:
            return 6
        }
    }

    public func evaluate(date: Date) throws -> Bool {
        return try evaluate(date: date).isValid
    }

    private func evaluate(date: Date) throws -> (isValid: Bool, ruleTimeUnitFailedOn: RecurrenceRuleTimeUnit?) {
        var ruleEvaluationState = EvaluationState.noComparisonAttempted
        var ruleTimeUnitFailedOn: RecurrenceRuleTimeUnit? = nil

        for ruleTimeUnit in recurrenceRuleTimeUnits {
            let constraint = resolveConstraint(ruleTimeUnit)
            guard let dateComponentValue = date.resolveDateComponentValue(for: ruleTimeUnit) else {
                throw RecurrenceRuleError.couldNotResolveDateComponentValueFromRecurrenceRuleTimeUnit
            }

            // evaluate the constraint
            let constraintEvalutionState = constraint.evaluate(dateComponentValue)

            if constraintEvalutionState != .noComparisonAttempted {
                ruleEvaluationState = constraintEvalutionState
            } else {
                let lowestCadence = resolveLowestCadence()
                let lowestCadenceLevel = resolveCadenceLevel(lowestCadence)
                let currentConstraintCadenceLevel = resolveCadenceLevel(ruleTimeUnit)

                /// If second, minute, hour, dayOfMonth or month constraints are not set
                /// they must be at their default values to avoid rule passing on every second
                if (currentConstraintCadenceLevel <= lowestCadenceLevel) {
                    if ruleTimeUnit == .second && dateComponentValue != 0 {
                        ruleEvaluationState = .failed
                    } else if ruleTimeUnit == .minute && dateComponentValue != 0 {
                        ruleEvaluationState = .failed
                    } else if ruleTimeUnit == .hour && dateComponentValue != 0 {
                        ruleEvaluationState = .failed
                    } else if ruleTimeUnit == .dayOfMonth && dateComponentValue != 1 {
                        ruleEvaluationState = .failed
                    } else if ruleTimeUnit == .month && dateComponentValue != 1 {
                        ruleEvaluationState = .failed
                    }
                }
            }

            if ruleEvaluationState == .failed {
                // break  iteraton
                ruleTimeUnitFailedOn = ruleTimeUnit
                break
            }

        }

        if ruleEvaluationState == .passing {
            return (isValid: true, ruleTimeUnitFailedOn)
        } else {
            return (isValid: false, ruleTimeUnitFailedOn)
        }
    }

    private func isYearConstraintPossible(date: Date) -> Bool {
        let currentYear = date.year()!

        if yearConstraint.isConstraintActive {
            for year in yearConstraint.setConstraint {
                if year >= currentYear {
                    return true
                }
            }

            if let rangeConstraint = yearConstraint.rangeConstraint {
                if rangeConstraint.contains(currentYear) {
                    return true
                }
            }

            if yearConstraint.stepConstraint != nil {
                return true
            }

            return false
        } else {
            return true
        }
    }

    private func resolveTimeUnitOfActiveConstraintWithLowestCadenceLevel() -> RecurrenceRuleTimeUnit? {
        var activeConstraintTimeUnitWithLowestCadenceLevel: RecurrenceRuleTimeUnit? = nil

        for ruleTimeUnit in recurrenceRuleTimeUnits {
            let constraint = resolveConstraint(ruleTimeUnit)
            if constraint.isConstraintActive {
                activeConstraintTimeUnitWithLowestCadenceLevel = ruleTimeUnit
            }
        }

        return activeConstraintTimeUnitWithLowestCadenceLevel
    }

    private func resolveNextValidValue(for ruleTimeUnit: RecurrenceRuleTimeUnit, date: Date) throws -> Int {
        guard let currentValue = date.resolveDateComponentValue(for: ruleTimeUnit) else {
            throw RecurrenceRuleError.couldNotResolveDateComponentValueFromRecurrenceRuleTimeUnit
        }

        switch ruleTimeUnit {
        case .second:
            return secondConstraint.nextValidValue(currentValue: currentValue)!
        case .minute:
            return minuteConstraint.nextValidValue(currentValue: currentValue)!
        case .hour:
           return hourConstraint.nextValidValue(currentValue: currentValue)!
        case .dayOfWeek:
            return dayOfWeekConstraint.nextValidValue(currentValue: currentValue)!
        case .dayOfMonth:
            return dayOfMonthConstraint.nextValidValue(currentValue: currentValue)!
        case .weekOfMonth:
            return weekOfMonthConstraint.nextValidValue(currentValue: currentValue)!
        case .weekOfYear:
            return weekOfYearConstraint.nextValidValue(currentValue: currentValue)!
        case .month:
            return monthConstraint.nextValidValue(currentValue: currentValue)!
        case .quarter:
            return quarterConstraint.nextValidValue(currentValue: currentValue)!
        case .year:
            return yearConstraint.nextValidValue(currentValue: currentValue)!
        }

    }

    public func resolveNextDateThatSatisfiesRule(date: Date) throws -> Date {
        guard let timeUnitOfLowestActiveConstraint = resolveTimeUnitOfActiveConstraintWithLowestCadenceLevel() else {
            throw RecurrenceRuleError.noConstraintsSetForRecurrenceRule
        }

        var dateToTest = date.dateByIncrementing(timeUnitOfLowestActiveConstraint)
        if dateToTest == nil {
            throw RecurrenceRuleError.coundNotResolveNextInstanceWithin1000Years
        }

        var nextInstanceFound = false
        while isYearConstraintPossible(date: dateToTest!) && nextInstanceFound == false {
            if let ruleTimeUnitFailedOn = try self.evaluate(date: dateToTest!).ruleTimeUnitFailedOn {
                let nextValidValue = try resolveNextValidValue(for: ruleTimeUnitFailedOn, date: dateToTest!)
                dateToTest = try dateToTest!.nextDateWhere(next: ruleTimeUnitFailedOn, is: nextValidValue)
            } else {
                nextInstanceFound = true
            }

            print(dateToTest!.componentsToString())
        }

        if nextInstanceFound {
            return dateToTest!
        } else {
            throw RecurrenceRuleError.coundNotResolveNextInstanceWithin1000Years
        }
    }

    
}
