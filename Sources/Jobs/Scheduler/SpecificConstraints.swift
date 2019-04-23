import Foundation

enum SpecificRecurrenceRuleConstraintError: Error {
    case incompatibleConstriantTimeUnit
}

protocol SpecificRecurrenceRuleConstraint {
    static var timeUnit: RecurrenceRuleTimeUnit { get }
    var constraint: RecurrenceRuleConstraint { get }

    init(constraint: RecurrenceRuleConstraint) throws
}

public struct YearRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRuleTimeUnit.year
    let constraint: RecurrenceRuleConstraint

    public init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit == YearRecurrenceRuleConstraint.timeUnit {
            self.constraint = constraint
        } else {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
    }

    /// The year the job will run pending all other constraints are met
    ///
    /// - Parameter year: Lower bound: 1970, Upper bound: 3000
    public static func atYear(_ year: Int) throws -> YearRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [year])
        return try .init(constraint: constraint)
    }

    /// The years the job will run pending all other constraints are met
    ///
    /// - Parameter year: Lower bound: 1970, Upper bound: 3000
    public static func atYears(_ years: Set<Int>) throws -> YearRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: years)
        return try .init(constraint: constraint)
    }

    /// The range of the years (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 3000
    public static func atYearsInRange(lowerBound: Int, upperBound: Int) throws -> YearRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound)
        return try .init(constraint: constraint)
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 including 0:
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter yearStep: the step value to be scheduled
    public static func yearStep(_ stepValue: Int) throws -> YearRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue)
        return try .init(constraint: constraint)
    }
}

public struct MonthRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRuleTimeUnit.month
    let constraint: RecurrenceRuleConstraint

    public init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit == MonthRecurrenceRuleConstraint.timeUnit {
            self.constraint = constraint
        } else {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
    }

    /// The month the job will run pending all other constraints are met
    ///
    /// - Note: 1 is January, 12 is December
    /// - Parameter month: Lower bound: 1, Upper bound: 12
    public static func atMonth(_ month: Int) throws -> MonthRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [month])
        return try .init(constraint: constraint)
    }

    /// The months the job will run pending all other constraints are met
    ///
    /// - Note: 1 is January, 12 is December
    /// - Parameter month: Lower bound: 1, Upper bound: 12
    public static func atMonths(_ months: Set<Int>) throws -> MonthRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: months)
        return try .init(constraint: constraint)
    }

    /// The range of the months (inclusive) the job will run pending all other constraints are met
    /// - Note: 1 is January, 12 is December
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 12
    public static func atMonthsInRange(lowerBound: Int, upperBound: Int) throws -> MonthRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound)
        return try .init(constraint: constraint)
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 including 0:
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter monthStep: the step value to be scheduled
    public static func monthStep(_ stepValue: Int) throws -> MonthRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue)
        return try .init(constraint: constraint)
    }
}

public struct DayOfMonthRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRuleTimeUnit.dayOfMonth
    let constraint: RecurrenceRuleConstraint

    public init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit == DayOfMonthRecurrenceRuleConstraint.timeUnit {
            self.constraint = constraint
        } else {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
    }

    /// The dayOfMonth the job will run pending all other constraints are met
    ///
    /// - Parameter dayOfMonth: Lower bound: 1, Upper bound: 31
    public static func atDayOfMonth(_ dayOfMonth: Int) throws -> DayOfMonthRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [dayOfMonth])
        return try .init(constraint: constraint)
    }

    /// The dayOfMonth the job will run pending all other constraints are met
    ///
    /// - Parameter dayOfMonth: Lower bound: 1, Upper bound: 31
    public static func atDaysOfMonth(_ daysOfMonth: Set<Int>) throws -> DayOfMonthRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: daysOfMonth)
        return try .init(constraint: constraint)
    }

    /// The range of the days of the month (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 31
    public static func atDaysOfMonthInRange(lowerBound: Int, upperBound: Int) throws -> DayOfMonthRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound)
        return try .init(constraint: constraint)
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 (including 0):
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter dayOfMonthStep: the step value to be scheduled
    public static func dayOfMonthStep(_ stepValue: Int) throws -> DayOfMonthRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue)
        return try .init(constraint: constraint)
    }
}

public struct DayOfWeekRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRuleTimeUnit.dayOfWeek
    let constraint: RecurrenceRuleConstraint

    public init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit == DayOfWeekRecurrenceRuleConstraint.timeUnit {
            self.constraint = constraint
        } else {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
    }

    /// The dayOfWeek the job will run pending all other constraints are met
    ///
    /// - Note: 1 is Sunday, 7 is Saturday
    /// - Parameter dayOfWeek: Lower bound: 1, Upper bound: 7
    public static func atDayOfWeek(_ dayOfWeek: Int) throws -> DayOfWeekRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [dayOfWeek])
        return try .init(constraint: constraint)
    }

    /// The dayOfWeek the job will run pending all other constraints are met
    ///
    /// - Note: 1 is Sunday, 7 is Saturday
    /// - Parameter dayOfWeek: Lower bound: 1, Upper bound: 7
    public static func atDaysOfWeek(_ dayOfWeeks: Set<Int>) throws -> DayOfWeekRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: dayOfWeeks)
        return try .init(constraint: constraint)
    }

    /// The range of the days of the week (inclusive) the job will run pending all other constraints are met
    /// - Note: 1 is Sunday, 7 is Saturday
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 7
    public static func atDaysOfWeekInRange(lowerBound: Int, upperBound: Int) throws -> DayOfWeekRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound)
        return try .init(constraint: constraint)
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 (including 0):
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter dayOfWeekStep: the step value to be scheduled
    public static func dayOfWeekStep(_ stepValue: Int) throws -> DayOfWeekRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue)
        return try .init(constraint: constraint)
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
    let constraint: RecurrenceRuleConstraint

    public init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit == HourRecurrenceRuleConstraint.timeUnit {
            self.constraint = constraint
        } else {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
    }

    /// The hour the job will run pending all other constraints are met
    ///
    /// - Parameter hour: Lower bound: 0, Upper bound: 23
    public static func atHour(_ hour: Int) throws -> HourRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [hour])
        return try .init(constraint: constraint)
    }

    /// The hour the job will run pending all other constraints are met
    ///
    /// - Note: Uses the 24 hour clock
    /// - Parameter hour: Lower bound: 0, Upper bound: 23
    public static func atHours(_ hours: Set<Int>) throws -> HourRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: hours)
        return try .init(constraint: constraint)
    }

    /// The range of hours (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 0
    /// - Parameter upperBound: must not greater than 23
    public static func atHoursInRange(lowerBound: Int, upperBound: Int) throws -> HourRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound)
        return try .init(constraint: constraint)
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 (including 0):
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter hourStep: the step value to be scheduled
    public static func hourStep(_ stepValue: Int) throws -> HourRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue)
        return try .init(constraint: constraint)
    }
}

public struct MinuteRecurrenceRuleConstraint: SpecificRecurrenceRuleConstraint {
    static let timeUnit = RecurrenceRuleTimeUnit.minute
    let constraint: RecurrenceRuleConstraint

    public init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit == MinuteRecurrenceRuleConstraint.timeUnit {
            self.constraint = constraint
        } else {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }
    }

    /// The minute the job will run pending all other constraints are met
    ///
    /// - Parameter minute: Lower bound: 0, Upper bound: 59
    public static func atMinute(_ minute: Int) throws -> MinuteRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [minute])
        return try .init(constraint: constraint)
    }

    /// The minute the job will run pending all other constraints are met
    ///
    /// - Parameter minute: Lower bound: 0, Upper bound: 59
    public static func atMinutes(_ minutes: Set<Int>) throws -> MinuteRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: minutes)
        return try .init(constraint: constraint)
    }

    /// The range of minutes (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 0
    /// - Parameter upperBound: must not greater than 59
    public static func atMinutesInRange(lowerBound: Int, upperBound: Int) throws -> MinuteRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound)
        return try .init(constraint: constraint)
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 (including 0):
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter minuteStep: the step value to be scheduled
    public static func minuteStep(_ stepValue: Int) throws -> MinuteRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue)
        return try .init(constraint: constraint)
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
    let constraint: RecurrenceRuleConstraint

    public init(constraint: RecurrenceRuleConstraint) throws {
        if constraint.timeUnit == SecondRecurrenceRuleConstraint.timeUnit {
            self.constraint = constraint
        } else {
            throw SpecificRecurrenceRuleConstraintError.incompatibleConstriantTimeUnit
        }

    }

    /// The second the job will run pending all other constraints are met
    ///
    /// - Parameter second: Lower bound: 0, Upper bound: 59
    public static func atSecond(_ second: Int) throws -> SecondRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [second])
        return try .init(constraint: constraint)
    }

    /// The second the job will run pending all other constraints are met
    ///
    /// - Parameter second: Lower bound: 0, Upper bound: 59
    public static func atSeconds(_ seconds: Set<Int>) throws -> SecondRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: seconds)
        return try .init(constraint: constraint)
    }

    /// The range of seconds (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 0
    /// - Parameter upperBound: 59
    public static func atSecondsInRange(lowerBound: Int, upperBound: Int) throws -> SecondRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound)
        return try .init(constraint: constraint)
    }

    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. (ex a step value in cron could be: */22)
    ///         For example: minuteStep(22) will be satisfied at every minute that is divisible by 22 (including 0):
    ///         ..., 3:44, 04:00, 04:22, 04:44, 05:00, 05:22, 05:44, 06:00 etc
    ///
    /// - Parameter secondStep: the step value to be scheduled
    public static func secondStep(_ stepValue: Int) throws -> SecondRecurrenceRuleConstraint {
        let constraint = try RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: stepValue)
        return try .init(constraint: constraint)
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
