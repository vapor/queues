import Foundation

enum SpecificRecurrenceRuleConstraintError: Error {
    case incompatibleConstriantTimeUnit
}

protocol SpecificRecurrenceRuleConstraint: RecurrenceRuleConstraintEvaluateable {
    static var timeUnit: RecurrenceRuleTimeUnit { get }
    static var validLowerBound: Int? { get }
    static var validUpperBound: Int?  { get }
    var _constraint: RecurrenceRuleConstraint { get }

    init(constraint: RecurrenceRuleConstraint) throws
}

// default implementations
extension SpecificRecurrenceRuleConstraint  {
    static var validLowerBound: Int? {
        return Calendar.gregorianLowerBound(for: timeUnit)
    }
    static var validUpperBound: Int? {
        return Calendar.gregorianUpperBound(for: Self.timeUnit)
    }

    public var lowestPossibleValue: Int? {
        return _constraint.lowestPossibleValue
    }

    public var highestPossibleValue: Int? {
        return _constraint.highestPossibleValue
    }

    public func evaluate(_ evaluationAmount: Int) -> EvaluationState {
        return _constraint.evaluate(evaluationAmount)
    }

    public func nextValidValue(currentValue: Int) -> Int? {
        return _constraint.nextValidValue(currentValue: currentValue)
    }
}


public struct YearRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRuleTimeUnit.year
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
    public static func atYear(_ year: Int) throws -> YearRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [year]))
    }

    /// The years the job will run pending all other constraints are met
    ///
    /// - Parameter year: Lower bound: 1970, Upper bound: 3000
    public static func atYears(_ years: Set<Int>) throws -> YearRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: years))
    }

    /// The range of the years (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 3000
    public static func atYearsInRange(lowerBound: Int, upperBound: Int) throws -> YearRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound))
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 including 0:
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter yearStep: the step value to be scheduled
    public static func yearStep(_ stepValue: Int) throws -> YearRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue))
    }
}

public struct MonthRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRuleTimeUnit.month
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
    public static func atMonth(_ month: Int) throws -> MonthRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [month]))
    }

    /// The months the job will run pending all other constraints are met
    ///
    /// - Note: 1 is January, 12 is December
    /// - Parameter month: Lower bound: 1, Upper bound: 12
    public static func atMonths(_ months: Set<Int>) throws -> MonthRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: months))
    }

    /// The range of the months (inclusive) the job will run pending all other constraints are met
    /// - Note: 1 is January, 12 is December
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 12
    public static func atMonthsInRange(lowerBound: Int, upperBound: Int) throws -> MonthRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound))
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 including 0:
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter monthStep: the step value to be scheduled
    public static func monthStep(_ stepValue: Int) throws -> MonthRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue))
    }
}

public struct DayOfMonthRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRuleTimeUnit.dayOfMonth
    let _constraint: RecurrenceRuleConstraint

    internal init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit != DayOfMonthRecurrenceRuleConstraint.timeUnit {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
        _constraint = constraint
    }

    /// The dayOfMonth the job will run pending all other constraints are met
    ///
    /// - Parameter dayOfMonth: Lower bound: 1, Upper bound: 31
    public static func atDayOfMonth(_ dayOfMonth: Int) throws -> DayOfMonthRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [dayOfMonth]))
    }

    /// The dayOfMonth the job will run pending all other constraints are met
    ///
    /// - Parameter dayOfMonth: Lower bound: 1, Upper bound: 31
    public static func atDaysOfMonth(_ daysOfMonth: Set<Int>) throws -> DayOfMonthRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: daysOfMonth))
    }

    /// The range of the days of the month (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 31
    public static func atDaysOfMonthInRange(lowerBound: Int, upperBound: Int) throws -> DayOfMonthRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound))
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 (including 0):
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter dayOfMonthStep: the step value to be scheduled
    public static func dayOfMonthStep(_ stepValue: Int) throws -> DayOfMonthRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue))
    }
}

public struct DayOfWeekRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRuleTimeUnit.dayOfWeek
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
    public static func atDayOfWeek(_ dayOfWeek: Int) throws -> DayOfWeekRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [dayOfWeek]))
    }

    /// The dayOfWeek the job will run pending all other constraints are met
    ///
    /// - Note: 1 is Sunday, 7 is Saturday
    /// - Parameter dayOfWeek: Lower bound: 1, Upper bound: 7
    public static func atDaysOfWeek(_ daysOfWeek: Set<Int>) throws -> DayOfWeekRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: daysOfWeek))
    }

    /// The range of the days of the week (inclusive) the job will run pending all other constraints are met
    /// - Note: 1 is Sunday, 7 is Saturday
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 7
    public static func atDaysOfWeekInRange(lowerBound: Int, upperBound: Int) throws -> DayOfWeekRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound))
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 (including 0):
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter dayOfWeekStep: the step value to be scheduled
    public static func dayOfWeekStep(_ stepValue: Int) throws -> DayOfWeekRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue))
    }

    // convenience

    /// Limits the Job to run on Sundays
    public static func sundays() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDayOfWeek(1)
    }

    /// Limits the Job to run on Mondays
    public static func mondays() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDayOfWeek(2)
    }

    /// Limits the Job to run on Tuesdays
    public static func tuesdays() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDayOfWeek(3)
    }

    /// Limits the Job to run on Wednesdays
    public static func wednesdays() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDayOfWeek(4)
    }

    /// Limits the Job to run on Thursdays
    public static func thursdays() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDayOfWeek(5)
    }

    /// Limits the Job to run on Fridays
    public static func fridays() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDayOfWeek(6)
    }

    /// Limits the Job to run on Saturdays
    public static func saturdays() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDayOfWeek(7)
    }

    /// Limits the Job to run on Weekdays (Mondays, Tuesdays, Wednesdays, Thursdays, Fridays)
    public static func weekdays() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDaysOfWeek([2, 3, 4, 5, 6])
    }

    /// Limits the Job to run on Weekends (Saturdays, Sundays)
    public static func weekends() throws -> DayOfWeekRecurrenceRuleConstraint {
        return try atDaysOfWeek([1, 7])
    }
}

public struct HourRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRuleTimeUnit.hour
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
    public static func atHour(_ hour: Int) throws -> HourRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [hour]))
    }

    /// The hour the job will run pending all other constraints are met
    ///
    /// - Note: Uses the 24 hour clock
    /// - Parameter hour: Lower bound: 0, Upper bound: 23
    public static func atHours(_ hours: Set<Int>) throws -> HourRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: hours))
    }

    /// The range of hours (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 0
    /// - Parameter upperBound: must not greater than 23
    public static func atHoursInRange(lowerBound: Int, upperBound: Int) throws -> HourRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound))
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 (including 0) in the hour:
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter hourStep: the step value to be scheduled
    public static func hourStep(_ stepValue: Int) throws -> HourRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue))
    }
}

public struct MinuteRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRuleTimeUnit.minute
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
    public static func atMinute(_ minute: Int) throws -> MinuteRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [minute]))
    }

    /// The minute the job will run pending all other constraints are met
    ///
    /// - Parameter minute: Lower bound: 0, Upper bound: 59
    public static func atMinutes(_ minutes: Set<Int>) throws -> MinuteRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: minutes))
    }

    /// The range of minutes (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 0
    /// - Parameter upperBound: must not greater than 59
    public static func atMinutesInRange(lowerBound: Int, upperBound: Int) throws -> MinuteRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound))
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 (including 0):
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter minuteStep: the step value to be scheduled
    public static func minuteStep(_ stepValue: Int) throws -> MinuteRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue))
    }

    // conveince

    /// Runs the job every minute
    public static func everyMinute() throws -> MinuteRecurrenceRuleConstraint {
        return try self.minuteStep(1)
    }

    /// Runs the job every 5 minutes
    public static func everyFiveMinutes() throws -> MinuteRecurrenceRuleConstraint {
        return try self.minuteStep(5)
    }

    /// Runs the job every 10 minutes
    public static func everyTenMinutes() throws -> MinuteRecurrenceRuleConstraint {
        return try self.minuteStep(10)
    }

    /// Runs the job every 15 minutes
    public static func everyFifteenMinutes() throws -> MinuteRecurrenceRuleConstraint {
        return try self.minuteStep(15)
    }

    /// Runs the job every 30 minutes
    public static func everyThirtyMinutes() throws -> MinuteRecurrenceRuleConstraint {
        return try self.minuteStep(30)
    }

}

public struct SecondRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRuleTimeUnit.second
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
    public static func atSecond(_ second: Int) throws -> SecondRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [second]))
    }

    /// The second the job will run pending all other constraints are met
    ///
    /// - Parameter second: Lower bound: 0, Upper bound: 59
    public static func atSeconds(_ seconds: Set<Int>) throws -> SecondRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: seconds))
    }

    /// The range of seconds (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 0
    /// - Parameter upperBound: 59
    public static func atSecondsInRange(lowerBound: Int, upperBound: Int) throws -> SecondRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound))
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 (including 0):
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter secondStep: the step value to be scheduled
    public static func secondStep(_ stepValue: Int) throws -> SecondRecurrenceRuleConstraint {
        return try .init(constraint: RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue))
    }

    // convenience
    /// Runs the job every second
    public static func everySecond() throws -> SecondRecurrenceRuleConstraint {
        return try self.secondStep(1)
    }

    /// Runs the job every 5 second
    public static func everyFiveSeconds() throws -> SecondRecurrenceRuleConstraint {
        return try self.secondStep(5)
    }

    /// Runs the job every 10 second
    public static func everyTenSeconds() throws -> SecondRecurrenceRuleConstraint {
        return try self.secondStep(10)
    }

    /// Runs the job every 15 second
    public static func everyFifteenSeconds() throws -> SecondRecurrenceRuleConstraint {
        return try self.secondStep(15)
    }

    /// Runs the job every 30 second
    public static func everyThirtySeconds() throws -> SecondRecurrenceRuleConstraint {
        return try self.secondStep(30)
    }
}




// other
public struct QuarterRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRuleTimeUnit.quarter
    let _constraint: RecurrenceRuleConstraint

    internal init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit != QuarterRecurrenceRuleConstraint.timeUnit {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
        _constraint = constraint
    }
}

public struct WeekOfYearRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRuleTimeUnit.weekOfYear
    let _constraint: RecurrenceRuleConstraint

    internal init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit != WeekOfYearRecurrenceRuleConstraint.timeUnit {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
        _constraint = constraint
    }
}

public struct WeekOfMonthRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRuleTimeUnit.weekOfMonth
    let _constraint: RecurrenceRuleConstraint

    internal init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit != WeekOfMonthRecurrenceRuleConstraint.timeUnit {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
        _constraint = constraint
    }
}
