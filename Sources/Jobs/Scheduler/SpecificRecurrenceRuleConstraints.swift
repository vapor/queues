import Foundation

enum SpecificRecurrenceRuleConstraintError: Error {
    case incompatibleConstriantTimeUnit
}

/// `SpecificRecurrenceRuleConstraint`s are limited to a single `RecurrenceRule.TimeUnit` and have static methods for convenient initialization
protocol SpecificRecurrenceRuleConstraint: RecurrenceRuleConstraintEvaluateable {
    static var timeUnit: RecurrenceRule.TimeUnit { get }
    static var validLowerBound: Int? { get }
    static var validUpperBound: Int? { get }
    var _constraint: RecurrenceRuleConstraint { get }

    init(constraint: RecurrenceRuleConstraint) throws
}

/// default implementations
extension SpecificRecurrenceRuleConstraint {
    /// The lower  bound of the constraint's `TimeUnit`
    static var validLowerBound: Int? {
        return Calendar.gregorianLowerBound(for: timeUnit)
    }

    /// The upper bound of the constraint's `TimeUnit`
    static var validUpperBound: Int? {
        return Calendar.gregorianUpperBound(for: timeUnit)
    }

    /// The lowest value that satisfies the constraint
    internal var lowestPossibleValue: Int? {
        return _constraint.lowestPossibleValue
    }

    /// The highest value that satisfies the constraint
    internal var highestPossibleValue: Int? {
        return _constraint.highestPossibleValue
    }

    /// Evaluates if a given amount satisfies the constraint
    internal func evaluate(_ evaluationAmount: Int) -> EvaluationState {
        return _constraint.evaluate(evaluationAmount)
    }

    /// Finds the the next value that satisfies the constraint
    internal func nextValidValue(currentValue: Int) -> Int? {
        return _constraint.nextValidValue(currentValue: currentValue)
    }
}

/// A constraint that limits the year value of a`RecurrenceRule` to given a set, range, or step
internal struct YearRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRule.TimeUnit.year
    let _constraint: RecurrenceRuleConstraint

    internal init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit != YearRecurrenceRuleConstraint.timeUnit {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
        _constraint = constraint
    }

    /// The year the job will run pending all other constraints are met
    ///
    /// - Parameter year: Lower bound: 1970, Upper bound: 3000
    internal static func atYear(_ year: Int) throws -> YearRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [year]))
    }

    /// The years the job will run pending all other constraints are met
    ///
    /// - Parameter year: Lower bound: 1970, Upper bound: 3000
    internal static func atYears(_ years: Set<Int>) throws -> YearRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: years))
    }

    /// The range of the years (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 3000
    internal static func atYearsInRange(lowerBound: Int, upperBound: Int) throws -> YearRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound))
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 including 0:
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter yearStep: the step value to be scheduled
    internal static func yearStep(_ stepValue: Int) throws -> YearRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue))
    }
}

/// A constraint that limits the quarter value of a`RecurrenceRule` to given a set, range, or step
internal struct QuarterRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRule.TimeUnit.quarter
    let _constraint: RecurrenceRuleConstraint

    internal init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit != QuarterRecurrenceRuleConstraint.timeUnit {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
        _constraint = constraint
    }

    /// The quarter the job will run pending all other constraints are met
    ///
    /// - Parameter quarter: Lower bound: 1, Upper bound: 4
    internal static func atQuarter(_ quarter: Int) throws -> QuarterRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [quarter]))
    }

    /// The quarters the job will run pending all other constraints are met
    ///
    /// - Parameter quarter: Lower bound: 1, Upper bound: 4
    internal static func atQuarters(_ quarters: Set<Int>) throws -> QuarterRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: quarters))
    }

    /// The range of the quarters (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 4
    internal static func atQuartersInRange(lowerBound: Int, upperBound: Int) throws -> QuarterRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound))
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 including 0:
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter quarterStep: the step value to be scheduled
    internal static func quarterStep(_ stepValue: Int) throws -> QuarterRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue))
    }
}

/// A constraint that limits the month value of a`RecurrenceRule` to given a set, range, or step
internal struct MonthRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRule.TimeUnit.month
    let _constraint: RecurrenceRuleConstraint

    internal init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit != MonthRecurrenceRuleConstraint.timeUnit {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
        _constraint = constraint
    }

    /// The month the job will run pending all other constraints are met
    ///
    /// - Note: 1 is January, 12 is December
    /// - Parameter month: Lower bound: 1, Upper bound: 12
    internal static func atMonth(_ month: Int) throws -> MonthRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [month]))
    }

    /// The months the job will run pending all other constraints are met
    ///
    /// - Note: 1 is January, 12 is December
    /// - Parameter month: Lower bound: 1, Upper bound: 12
    internal static func atMonths(_ months: Set<Int>) throws -> MonthRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: months))
    }

    /// The range of the months (inclusive) the job will run pending all other constraints are met
    /// - Note: 1 is January, 12 is December
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 12
    internal static func atMonthsInRange(lowerBound: Int, upperBound: Int) throws -> MonthRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound))
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 including 0:
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter monthStep: the step value to be scheduled
    internal static func monthStep(_ stepValue: Int) throws -> MonthRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue))
    }
}

/// A constraint that limits the dayOfMonth value of a`RecurrenceRule` to given a set, range, or step
internal struct DayOfMonthRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRule.TimeUnit.dayOfMonth
    let _constraint: RecurrenceRuleConstraint
    internal let isLimitedToLastDayOfMonth: Bool

    internal init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit != DayOfMonthRecurrenceRuleConstraint.timeUnit {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
        self.isLimitedToLastDayOfMonth = false
        _constraint = constraint
    }

    internal init(constraint: RecurrenceRuleConstraint, isLimitedToLastDayOfMonth: Bool = false) throws {
        if constraint.timeUnit != DayOfMonthRecurrenceRuleConstraint.timeUnit {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
        self.isLimitedToLastDayOfMonth = isLimitedToLastDayOfMonth
        _constraint = constraint
    }

    internal func evaluate(_ evaluationAmount: Int) -> EvaluationState {
        return _constraint.evaluate(evaluationAmount)
    }

    internal func nextValidValue(currentValue: Int) -> Int? {
        return _constraint.nextValidValue(currentValue: currentValue)
    }

    /// The dayOfMonth the job will run pending all other constraints are met
    ///
    /// - Parameter dayOfMonth: Lower bound: 1, Upper bound: 31
    internal static func atDayOfMonth(_ dayOfMonth: Int) throws -> DayOfMonthRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [dayOfMonth]))
    }

    /// The dayOfMonth the job will run pending all other constraints are met
    ///
    /// - Parameter dayOfMonth: Lower bound: 1, Upper bound: 31
    internal static func atDaysOfMonth(_ daysOfMonth: Set<Int>) throws -> DayOfMonthRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: daysOfMonth))
    }

    /// The range of the days of the month (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 31
    internal static func atDaysOfMonthInRange(lowerBound: Int, upperBound: Int) throws -> DayOfMonthRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound))
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 (including 0):
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter dayOfMonthStep: the step value to be scheduled
    internal static func dayOfMonthStep(_ stepValue: Int) throws -> DayOfMonthRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue))
    }

    /// Limits the job to run only on the last day of the month
    internal static func atLastDayOfMonth() throws -> DayOfMonthRecurrenceRuleConstraint {
        let isLimitedToLastDayOfMonth = true
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [28, 29, 30, 31]), isLimitedToLastDayOfMonth: isLimitedToLastDayOfMonth)
    }
}

/// A constraint that limits the dayOfWeek value of a`RecurrenceRule` to given a set, range, or step
internal struct DayOfWeekRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRule.TimeUnit.dayOfWeek
    let _constraint: RecurrenceRuleConstraint

    internal init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit != DayOfWeekRecurrenceRuleConstraint.timeUnit {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
        _constraint = constraint
    }

    /// The dayOfWeek the job will run pending all other constraints are met
    ///
    /// - Note: 1 is Sunday, 7 is Saturday
    /// - Parameter dayOfWeek: Lower bound: 1, Upper bound: 7
    internal static func atDayOfWeek(_ dayOfWeek: Int) throws -> DayOfWeekRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [dayOfWeek]))
    }

    /// The dayOfWeek the job will run pending all other constraints are met
    ///
    /// - Note: 1 is Sunday, 7 is Saturday
    /// - Parameter dayOfWeek: Lower bound: 1, Upper bound: 7
    internal static func atDaysOfWeek(_ daysOfWeek: Set<Int>) throws -> DayOfWeekRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: daysOfWeek))
    }

    /// The range of the days of the week (inclusive) the job will run pending all other constraints are met
    /// - Note: 1 is Sunday, 7 is Saturday
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 7
    internal static func atDaysOfWeekInRange(lowerBound: Int, upperBound: Int) throws -> DayOfWeekRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound))
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 (including 0):
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter dayOfWeekStep: the step value to be scheduled
    internal static func dayOfWeekStep(_ stepValue: Int) throws -> DayOfWeekRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue))
    }

    // convenience
    /// Limits the Job to run on Sundays
    internal static func sundays() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDayOfWeek(1)
    }

    /// Limits the Job to run on Mondays
    internal static func mondays() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDayOfWeek(2)
    }

    /// Limits the Job to run on Tuesdays
    internal static func tuesdays() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDayOfWeek(3)
    }

    /// Limits the Job to run on Wednesdays
    internal static func wednesdays() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDayOfWeek(4)
    }

    /// Limits the Job to run on Thursdays
    internal static func thursdays() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDayOfWeek(5)
    }

    /// Limits the Job to run on Fridays
    internal static func fridays() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDayOfWeek(6)
    }

    /// Limits the Job to run on Saturdays
    internal static func saturdays() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDayOfWeek(7)
    }

    /// Limits the Job to run on Weekdays (Mondays, Tuesdays, Wednesdays, Thursdays, Fridays)
    internal static func weekdays() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDaysOfWeek([2, 3, 4, 5, 6])
    }

    /// Limits the Job to run on Weekends (Saturdays, Sundays)
    internal static func weekends() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDaysOfWeek([1, 7])
    }
}

/// A constraint that limits the hour value of a`RecurrenceRule` to given a set, range, or step
internal struct HourRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRule.TimeUnit.hour
    let _constraint: RecurrenceRuleConstraint

    internal init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit != HourRecurrenceRuleConstraint.timeUnit {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
        _constraint = constraint
    }

    /// The hour the job will run pending all other constraints are met
    ///
    /// - Parameter hour: Lower bound: 0, Upper bound: 23
    internal static func atHour(_ hour: Int) throws -> HourRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [hour]))
    }

    /// The hour the job will run pending all other constraints are met
    ///
    /// - Note: Uses the 24 hour clock
    /// - Parameter hour: Lower bound: 0, Upper bound: 23
    internal static func atHours(_ hours: Set<Int>) throws -> HourRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: hours))
    }

    /// The range of hours (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 0
    /// - Parameter upperBound: must not greater than 23
    internal static func atHoursInRange(lowerBound: Int, upperBound: Int) throws -> HourRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound))
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 (including 0) in the hour:
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter hourStep: the step value to be scheduled
    internal static func hourStep(_ stepValue: Int) throws -> HourRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue))
    }
}

/// A constraint that limits the minute value of a`RecurrenceRule` to given a set, range, or step
internal struct MinuteRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRule.TimeUnit.minute
    let _constraint: RecurrenceRuleConstraint

    internal init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit != MinuteRecurrenceRuleConstraint.timeUnit {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
        _constraint = constraint
    }

    /// The minute the job will run pending all other constraints are met
    ///
    /// - Parameter minute: Lower bound: 0, Upper bound: 59
    internal static func atMinute(_ minute: Int) throws -> MinuteRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [minute]))
    }

    /// The minute the job will run pending all other constraints are met
    ///
    /// - Parameter minute: Lower bound: 0, Upper bound: 59
    internal static func atMinutes(_ minutes: Set<Int>) throws -> MinuteRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: minutes))
    }

    /// The range of minutes (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 0
    /// - Parameter upperBound: must not greater than 59
    internal static func atMinutesInRange(lowerBound: Int, upperBound: Int) throws -> MinuteRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound))
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 (including 0):
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter minuteStep: the step value to be scheduled
    internal static func minuteStep(_ stepValue: Int) throws -> MinuteRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue))
    }

    // conveince
    /// Runs the job every minute
    internal static func everyMinute() throws -> MinuteRecurrenceRuleConstraint {
        return try self.minuteStep(1)
    }

    /// Runs the job every 5 minutes
    internal static func everyFiveMinutes() throws -> MinuteRecurrenceRuleConstraint {
        return try self.minuteStep(5)
    }

    /// Runs the job every 10 minutes
    internal static func everyTenMinutes() throws -> MinuteRecurrenceRuleConstraint {
        return try self.minuteStep(10)
    }

    /// Runs the job every 15 minutes
    internal static func everyFifteenMinutes() throws -> MinuteRecurrenceRuleConstraint {
        return try self.minuteStep(15)
    }

    /// Runs the job every 30 minutes
    internal static func everyThirtyMinutes() throws -> MinuteRecurrenceRuleConstraint {
        return try self.minuteStep(30)
    }

}

/// A constraint that limits the second value of a`RecurrenceRule` to given a set, range, or step
internal struct SecondRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRule.TimeUnit.second
    let _constraint: RecurrenceRuleConstraint

    internal init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit != SecondRecurrenceRuleConstraint.timeUnit {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
        _constraint = constraint
    }

    /// The second the job will run pending all other constraints are met
    ///
    /// - Parameter second: Lower bound: 0, Upper bound: 59
    internal static func atSecond(_ second: Int) throws -> SecondRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [second]))
    }

    /// The second the job will run pending all other constraints are met
    ///
    /// - Parameter second: Lower bound: 0, Upper bound: 59
    internal static func atSeconds(_ seconds: Set<Int>) throws -> SecondRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: seconds))
    }

    /// The range of seconds (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 0
    /// - Parameter upperBound: 59
    internal static func atSecondsInRange(lowerBound: Int, upperBound: Int) throws -> SecondRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound))
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 (including 0):
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter secondStep: the step value to be scheduled
    internal static func secondStep(_ stepValue: Int) throws -> SecondRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue))
    }

    // convenience
    /// Runs the job every second
    internal static func everySecond() throws -> SecondRecurrenceRuleConstraint {
        return try self.secondStep(1)
    }

    /// Runs the job every 5 second
    internal static func everyFiveSeconds() throws -> SecondRecurrenceRuleConstraint {
        return try self.secondStep(5)
    }

    /// Runs the job every 10 second
    internal static func everyTenSeconds() throws -> SecondRecurrenceRuleConstraint {
        return try self.secondStep(10)
    }

    /// Runs the job every 15 second
    internal static func everyFifteenSeconds() throws -> SecondRecurrenceRuleConstraint {
        return try self.secondStep(15)
    }

    /// Runs the job every 30 second
    internal static func everyThirtySeconds() throws -> SecondRecurrenceRuleConstraint {
        return try self.secondStep(30)
    }
}
