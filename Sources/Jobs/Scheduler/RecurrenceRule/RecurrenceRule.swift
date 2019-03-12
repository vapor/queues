import Foundation

enum RecurrenceRuleError: Error {
    case lowerBoundGreaterThanUpperBound
    case noSetConstraintForRecurrenceRuleTimeUnit
    case couldNotResolveDateComponentValueFromRecurrenceRuleTimeUnit
    case noConstraintsSetForRecurrenceRule
    case coundNotResolveNextInstanceWithin1000Years
    case couldNotResolveYearConstraitFromDate
    case couldNotResloveNextValueFromConstraint
}

/// Defines the rule for when to run a job based on the given constraints
///
/// - warning: RecurrenceRule only supports the Gregorian calendar (i.e. Calendar.identifier.gregorian or Calendar.identifier.iso8601)
///
/// - Note: RecurrenceRule uses the local TimeZone as default
public struct RecurrenceRule {
    var timeZone = TimeZone.current
    let yearConstraint: RecurrenceRuleConstraint
    var quarterConstraint: RecurrenceRuleConstraint
    let monthConstraint: RecurrenceRuleConstraint
    let weekOfYearConstraint: RecurrenceRuleConstraint
    let weekOfMonthConstraint: RecurrenceRuleConstraint
    let dayOfMonthConstraint: RecurrenceRuleConstraint
    let dayOfWeekConstraint: RecurrenceRuleConstraint
    let hourConstraint: RecurrenceRuleConstraint
    let minuteConstraint: RecurrenceRuleConstraint
    var secondConstraint: RecurrenceRuleConstraint

    private let recurrenceRuleTimeUnits: [RecurrenceRuleTimeUnit] = [
        .year,
        .quarter,
        .month,
        .weekOfYear,
        .weekOfMonth,
        .dayOfMonth,
        .dayOfWeek,
        .hour,
        .minute,
        .second
    ]

    init(timeZone: TimeZone = TimeZone.current) throws {
        self.timeZone = timeZone
        yearConstraint = RecurrenceRuleSetConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .year),
                                                       validUpperBound: try Calendar.current.upperBound(for: .year))
        quarterConstraint = RecurrenceRuleSetConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .quarter),
                                                       validUpperBound: try Calendar.current.upperBound(for: .quarter))
        monthConstraint = RecurrenceRuleSetConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .month),
                                                          validUpperBound: try Calendar.current.upperBound(for: .month))
        weekOfYearConstraint = RecurrenceRuleSetConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .weekOfYear),
                                                          validUpperBound: try Calendar.current.upperBound(for: .weekOfYear))
        weekOfMonthConstraint = RecurrenceRuleSetConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .weekOfMonth),
                                                          validUpperBound: try Calendar.current.upperBound(for: .weekOfMonth))
        dayOfMonthConstraint = RecurrenceRuleSetConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .dayOfMonth),
                                                          validUpperBound: try Calendar.current.upperBound(for: .dayOfMonth))
        dayOfWeekConstraint = RecurrenceRuleSetConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .dayOfWeek),
                                                          validUpperBound: try Calendar.current.upperBound(for: .dayOfWeek))
        hourConstraint = RecurrenceRuleSetConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .hour),
                                                            validUpperBound: try Calendar.current.upperBound(for: .hour))
        minuteConstraint = RecurrenceRuleSetConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .minute),
                                                            validUpperBound: try Calendar.current.upperBound(for: .minute))
        secondConstraint = RecurrenceRuleSetConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .second),
                                                            validUpperBound: try Calendar.current.upperBound(for: .second))
    }

    private init(from ruleToCopy: RecurrenceRule, updatingConstraint ruleTimeUnit: RecurrenceRuleTimeUnit, with newConstraint: RecurrenceRuleConstraint) {
        self.timeZone = ruleToCopy.timeZone

        ruleTimeUnit == .year ? (self.yearConstraint = newConstraint) :
            (self.yearConstraint = ruleToCopy.yearConstraint)
        ruleTimeUnit == .quarter ? (self.quarterConstraint = newConstraint) :
            (self.quarterConstraint = ruleToCopy.quarterConstraint)
        ruleTimeUnit == .month ? (self.monthConstraint = newConstraint) :
            (self.monthConstraint = ruleToCopy.monthConstraint)
        ruleTimeUnit == .weekOfYear ? (self.weekOfYearConstraint = newConstraint) :
            (self.weekOfYearConstraint = ruleToCopy.weekOfYearConstraint)
        ruleTimeUnit == .weekOfMonth ? (self.weekOfMonthConstraint = newConstraint) :
            (self.weekOfMonthConstraint = ruleToCopy.weekOfMonthConstraint)
        ruleTimeUnit == .dayOfMonth ? (self.dayOfMonthConstraint = newConstraint) :
            (self.dayOfMonthConstraint = ruleToCopy.dayOfMonthConstraint)
        ruleTimeUnit == .dayOfWeek ? (self.dayOfWeekConstraint = newConstraint) :
            (self.dayOfWeekConstraint = ruleToCopy.dayOfWeekConstraint)
        ruleTimeUnit == .hour ? (self.hourConstraint = newConstraint) :
            (self.hourConstraint = ruleToCopy.hourConstraint)
        ruleTimeUnit == .minute ? (self.minuteConstraint = newConstraint) :
            (self.minuteConstraint = ruleToCopy.minuteConstraint)
        ruleTimeUnit == .second ? (self.secondConstraint = newConstraint) :
            (self.secondConstraint = ruleToCopy.secondConstraint)
    }

    private init(from ruleToCopy: RecurrenceRule, updatingTimeZone timeZone: TimeZone) {
        self.timeZone = timeZone

        yearConstraint = ruleToCopy.yearConstraint
        quarterConstraint = ruleToCopy.quarterConstraint
        monthConstraint = ruleToCopy.monthConstraint
        weekOfYearConstraint = ruleToCopy.weekOfYearConstraint
        weekOfMonthConstraint = ruleToCopy.weekOfMonthConstraint
        dayOfMonthConstraint = ruleToCopy.dayOfMonthConstraint
        dayOfWeekConstraint = ruleToCopy.dayOfWeekConstraint
        hourConstraint = ruleToCopy.hourConstraint
        minuteConstraint = ruleToCopy.minuteConstraint
        secondConstraint = ruleToCopy.secondConstraint
    }

    ///  Sets the timeZone used by rule constraintss
    ///
    /// - Parameter timeZone: The TimeZone constraints reference against
    public func usingTimeZone(_ timeZone: TimeZone) throws -> RecurrenceRule {
        return RecurrenceRule.init(from: self, updatingTimeZone: timeZone)
    }

    // step
    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. For example: every(.minutes(22)).atHours([4, 5]) the rule will
    ///         be satisfied at: 04:00, 04:22, 04:44, 05:00, 05:22, and 05:44
    ///
    /// - Parameter timeAmount: timeAmount to be scheduled
    public func every(_ timeAmount: RecurrenceRuleTimeAmount) throws -> RecurrenceRule {
        let constraintToCopy = resolveConstraint(timeAmount.timeUnit)
        let newConstraint = try RecurrenceRuleStepConstraint.init(from: constraintToCopy, stepConstraint: timeAmount.amount)
        return RecurrenceRule.init(from: self, updatingConstraint: timeAmount.timeUnit, with: newConstraint)
    }

    // step convenience functions
    // seconds
    /// Runs the job every second
    public func everySecond() throws -> RecurrenceRule {
        return try every(.seconds(1))
    }

    /// Runs the job every 5 second
    public func everyFiveSeconds() throws -> RecurrenceRule {
        return try every(.seconds(5))
    }

    /// Runs the job every 10 second
    public func everyTenSeconds() throws -> RecurrenceRule {
        return try every(.seconds(10))
    }

    /// Runs the job every 15 second
    public func everyFifteenSeconds() throws -> RecurrenceRule {
        return try every(.seconds(15))
    }

    /// Runs the job every 30 second
    public func every30Seconds() throws -> RecurrenceRule {
        return try every(.seconds(30))
    }

    // minutes
    /// Runs the job every minute
    public func everyMinute() throws -> RecurrenceRule {
        return try every(.minutes(1))
    }

    /// Runs the job every 5 minutes
    public func everyFiveMinutes() throws -> RecurrenceRule {
        return try every(.minutes(5))
    }

    /// Runs the job every 10 minutes
    public func everyTenMinutes() throws -> RecurrenceRule {
        return try every(.minutes(10))
    }

    /// Runs the job every 15 minutes
    public func everyFifteenMinutes() throws -> RecurrenceRule {
        return try every(.minutes(15))
    }

    /// Runs the job every 30 minutes
    public func every30Minutes() throws -> RecurrenceRule {
        return try every(.minutes(30))
    }

    // hours
    /// Runs the job every hour
    public func hourly() throws -> RecurrenceRule {
        return try every(.hours(1))
    }

    // dayOfWeek
    /// Runs the job every week (run on Sunday)
    public func weekly() throws -> RecurrenceRule {
        return try every(.daysOfWeek(1))
    }

    public func weekly(onDayOfWeek dayOfWeek: Int) throws -> RecurrenceRule {
         return try every(.daysOfWeek(dayOfWeek))
    }

    // dayOfMonths
    /// Runs the job every day (run at midnight by default)
    public func daily() throws -> RecurrenceRule {
        return try every(.daysOfMonth(1))
    }

    // quarter
    /// Runs the job every quarter
    public func quarterly() throws -> RecurrenceRule {
        return try every(.quarters(1))
    }

    /// Runs the job every year
    public func yearly() throws -> RecurrenceRule {
        return try every(.years(1))
    }

    /// The second the job will run pending all other constraints are met
    ///
    /// - Parameter second: Lower bound: 0, Upper bound: 59
    public func atSecond(_ second: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .second, withValue: second)
    }

    /// The minute the job will run pending all other constraints are met
    ///
    /// - Parameter minute: Lower bound: 0, Upper bound: 59
    public func atMinute(_ minute: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .minute, withValue: minute)
    }

    /// The hour the job will run pending all other constraints are met
    ///
    /// - Parameter hour: Lower bound: 0, Upper bound: 23
    public func atHour(_ hour: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .hour, withValue: hour)
    }

    /// The dayOfWeek the job will run pending all other constraints are met
    ///
    /// - Note: 1 is Sunday, 7 is Saturday
    /// - Parameter dayOfWeek: Lower bound: 1, Upper bound: 7
    public func atDayOfWeek(_ dayOfWeek: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .dayOfWeek, withValue: dayOfWeek)
    }

    /// The dayOfMonth the job will run pending all other constraints are met
    ///
    /// - Parameter dayOfMonth: Lower bound: 1, Upper bound: 31
    public func atDayOfMonth(_ dayOfMonth: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .dayOfMonth, withValue: dayOfMonth)
    }

    /// The weekOfMonth the job will run pending all other constraints are met
    ///
    /// - Parameter dayOfMonth: Lower bound: 1, Upper bound: 5
    public func atWeekOfMonth(_ weekOfMonth: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .weekOfMonth, withValue: weekOfMonth)
    }

    /// The weekOfYear the job will run pending all other constraints are met
    ///
    /// - Parameter weekOfYear: Lower bound: 1, Upper bound: 52
    public func atWeekOfYear(_ weekOfYear: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .weekOfYear, withValue: weekOfYear)
    }

    /// The month the job will run pending all other constraints are met
    ///
    /// - Note: 1 is January, 12 is December
    /// - Parameter month: Lower bound: 1, Upper bound: 12
    public func atMonth(_ month: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .month, withValue: month)
    }

    /// The quarter the job will run pending all other constraints are met
    ///
    /// - Parameter year: Lower bound: 1, Upper bound: 4
    public func atQuarter(_ quarter: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .quarter, withValue: quarter)
    }

    /// The year the job will run pending all other constraints are met
    ///
    /// - Parameter year: Lower bound: 1970, Upper bound: 3000
    public func atYear(_ year: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .year, withValue: year)
    }

    // conveniene methods for set

    /// Limits the Job to run on Sundays
    public func sundays() throws -> RecurrenceRule {
        return try atDayOfWeek(1)
    }

    /// Limits the Job to run on Mondays
    public func mondays() throws -> RecurrenceRule {
        return try atDayOfWeek(2)
    }

    /// Limits the Job to run on Tuesdays
    public func tuesdays() throws -> RecurrenceRule {
        return try atDayOfWeek(3)
    }

    /// Limits the Job to run on Wednesdays
    public func wednesdays() throws -> RecurrenceRule {
        return try atDayOfWeek(4)
    }

    /// Limits the Job to run on Thursdays
    public func thursdays() throws -> RecurrenceRule {
        return try atDayOfWeek(5)
    }

    /// Limits the Job to run on Fridays
    public func fridays() throws -> RecurrenceRule {
        return try atDayOfWeek(6)
    }

    /// Limits the Job to run on Saturdays
    public func saturdays() throws -> RecurrenceRule {
        return try atDayOfWeek(7)
    }

    /// Limits the Job to run on Weekdays (Mondays, Tuesdays, Wednesdays, Thursdays, Fridays)
    public func weekdays() throws -> RecurrenceRule {
        return try atDaysOfWeek([2, 3, 4, 5, 6])
    }

    /// Limits the Job to run on Weekends (Saturdays, Sundays)
    public func weekends() throws -> RecurrenceRule {
        return try atDaysOfWeek([1, 7])
    }

    // add array to set
    /// The seconds the job will run pending all other constraints are met
    ///
    /// - Parameter seconds: Lower bound: 0, Upper bound: 59
    public func atSeconds(_ seconds: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .second, withValues: seconds)
    }

    /// The minutes the job will run pending all other constraints are met
    ///
    /// - Parameter minutes: Lower bound: 0, Upper bound: 59
    public func atMinutes(_ minutes: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .minute, withValues: minutes)
    }

    /// The hours the job will run pending all other constraints are met
    ///
    /// - Parameter hours: Lower bound: 0, Upper bound: 23
    public func atHours(_ hours: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .hour, withValues: hours)
    }

    /// The days of the week the job will run pending all other constraints are met
    ///
    /// - Note: 1 is Sunday, 7 is Saturday
    /// - Parameter daysOfWeek: Lower bound: 1, Upper bound: 7
    public func atDaysOfWeek(_ daysOfWeek: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .dayOfWeek, withValues: daysOfWeek)
    }

    /// The days of the month the job will run pending all other constraints are met
    ///
    /// - Parameter daysOfMonth: Lower bound: 1, Upper bound: 31
    public func atDaysOfMonth(_ daysOfMonth: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .dayOfMonth, withValues: daysOfMonth)
    }

    /// The weeks of the month the job will run pending all other constraints are met
    ///
    /// - Parameter weeksOfMonth: Lower bound: 1, Upper bound: 5
    public func atWeeksOfMonth(_ weeksOfMonth: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .weekOfMonth, withValues: weeksOfMonth)
    }

    /// The weeks of the year the job will run pending all other constraints are met
    ///
    /// - Parameter weeksOfYear: Lower bound: 1, Upper bound: 52
    public func atWeeksOfYear(_ weeksOfYear: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .weekOfYear, withValues: weeksOfYear)
    }

    /// The months the job will run pending all other constraints are met
    ///
    /// - Note: 1 is January, 12 is December
    /// - Parameter months: Lower bound: 1, Upper bound: 12
    public func atMonths(_ months: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .month, withValues: months)
    }

    /// The quarters the job will run pending all other constraints are met
    ///
    /// - Parameter quarter: Lower bound: 1, Upper bound: 4
    public func atQuarters(_ quarters: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .quarter, withValues: quarters)
    }

    /// The years the job will run pending all other constraints are met
    ///
    /// - Parameter year: Lower bound: 1970, Upper bound: 3000
    public func atYears(_ years: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .year, withValues: years)
    }

    // ranges
    /// The range of seconds (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 0
    /// - Parameter upperBound: 59
    public func whenSecondInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .second, withRange: lowerBound...upperBound)
    }

    /// The range of minutes (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 0
    /// - Parameter upperBound: must not greater than 59
    public func whenMinuteInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .minute, withRange: lowerBound...upperBound)
    }

    /// The range of hours (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 0
    /// - Parameter upperBound: must not greater than 23
    public func whenHourInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .hour, withRange: lowerBound...upperBound)
    }

    /// The range of the days of the week (inclusive) the job will run pending all other constraints are met
    /// - Note: 1 is Sunday, 7 is Saturday
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 7
    public func whenDayOfWeekInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .dayOfWeek, withRange: lowerBound...upperBound)
    }

    /// The range of the days of the month (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 31
    public func whenDayOfMonthInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .dayOfMonth, withRange: lowerBound...upperBound)
    }

    /// The range of the weeks of the month (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 5
    public func whenWeeksOfMonthInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .weekOfMonth, withRange: lowerBound...upperBound)
    }

    /// The range of the weeks of the year (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 52
    public func whenWeeksOfYearInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .weekOfYear, withRange: lowerBound...upperBound)
    }

    /// The range of the months (inclusive) the job will run pending all other constraints are met
    /// - Note: 1 is January, 12 is December
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 12
    public func whenMonthInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .month, withRange: lowerBound...upperBound)
    }

    /// The range of the quarters (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least  1
    /// - Parameter upperBound: must not greater than 4
    public func whenQuarterInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .quarter, withRange: lowerBound...upperBound)
    }

    /// The range of the years (inclusive) the job will run pending all other constraints are met
    /// - Parameter lowerBound: must be at least 1
    /// - Parameter upperBound: must not greater than 3000
    public func whenYearInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .year, withRange: lowerBound...upperBound)
    }

    /// Evaluates if the constraints are satified at a given date
    ///
    /// - Parameter date: The date to test the constraints against
    /// - Returns: returns true if all constraints are satisfied for the given date
    public func evaluate(date: Date) throws -> Bool {
        return try evaluate(date: date).isValid
    }

    private func evaluate(date: Date) throws -> (isValid: Bool, ruleTimeUnitFailedOn: RecurrenceRuleTimeUnit?) {
        var ruleEvaluationState = EvaluationState.noComparisonAttempted
        var ruleTimeUnitFailedOn: RecurrenceRuleTimeUnit?

        for ruleTimeUnit in recurrenceRuleTimeUnits {
            let constraint = resolveConstraint(ruleTimeUnit)
            guard let dateComponentValue = date.dateComponentValue(for: ruleTimeUnit, atTimeZone: timeZone) else {
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

    /// Finds the next date from the starting date that satisfies the rule
    ///
    /// - Parameter date: The starting date
    /// - Returns: The next date that satisfies the rule
    public func resolveNextDateThatSatisfiesRule(date: Date) throws -> Date {
        guard let timeUnitOfLowestActiveConstraint = resolveTimeUnitOfActiveConstraintWithLowestCadenceLevel() else {
            throw RecurrenceRuleError.noConstraintsSetForRecurrenceRule
        }

        var dateToTest = date.dateByIncrementing(timeUnitOfLowestActiveConstraint)

        var nextInstanceFound = false
        while nextInstanceFound == false {
            guard let currentDateToTest = dateToTest else {
                throw RecurrenceRuleError.coundNotResolveNextInstanceWithin1000Years
            }
            if try isYearConstraintPossible(date: currentDateToTest) == false {
                throw RecurrenceRuleError.coundNotResolveNextInstanceWithin1000Years
            }

            if let ruleTimeUnitFailedOn = try self.evaluate(date: currentDateToTest).ruleTimeUnitFailedOn {
                let nextValidValue = try resolveNextValidValue(for: ruleTimeUnitFailedOn, date: currentDateToTest)
                dateToTest = try currentDateToTest.nextDate(where: ruleTimeUnitFailedOn, is: nextValidValue, atTimeZone: timeZone)
            } else {
                nextInstanceFound = true
            }
        }

        if nextInstanceFound {
            if let nextDate = dateToTest {
                return nextDate
            } else {
                throw RecurrenceRuleError.coundNotResolveNextInstanceWithin1000Years
            }
        } else {
            throw RecurrenceRuleError.coundNotResolveNextInstanceWithin1000Years
        }
    }

    private func resolveTimeUnitOfActiveConstraintWithLowestCadenceLevel() -> RecurrenceRuleTimeUnit? {
        var activeConstraintTimeUnitWithLowestCadenceLevel: RecurrenceRuleTimeUnit?

        for ruleTimeUnit in recurrenceRuleTimeUnits {
            let constraint = resolveConstraint(ruleTimeUnit)
            if constraint.isConstraintActive {
                activeConstraintTimeUnitWithLowestCadenceLevel = ruleTimeUnit
            }
        }

        return activeConstraintTimeUnitWithLowestCadenceLevel
    }

    private func resolveNextValidValue(for ruleTimeUnit: RecurrenceRuleTimeUnit, date: Date) throws -> Int {
        guard let currentValue = date.dateComponentValue(for: ruleTimeUnit, atTimeZone: timeZone) else {
            throw RecurrenceRuleError.couldNotResolveDateComponentValueFromRecurrenceRuleTimeUnit
        }

        let constraint = resolveConstraint(ruleTimeUnit)
        guard let nextValidValue = constraint.nextValidValue(currentValue: currentValue) else {
            throw RecurrenceRuleError.couldNotResloveNextValueFromConstraint
        }

        return nextValidValue
    }

    private func resolveConstraint(_ ruleTimeUnit: RecurrenceRuleTimeUnit) -> RecurrenceRuleConstraint {
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

    private func recurrenceRule(updating ruleTimeUnit: RecurrenceRuleTimeUnit, withValue value: Int) throws -> RecurrenceRule {
        let constraintToCopy = resolveConstraint(ruleTimeUnit)
        let newConstraint = try RecurrenceRuleSetConstraint.init(from: constraintToCopy, setConstraint: [value])
        return RecurrenceRule.init(from: self, updatingConstraint: ruleTimeUnit, with: newConstraint)
    }

    private func recurrenceRule(updating ruleTimeUnit: RecurrenceRuleTimeUnit, withValues values: Set<Int>) throws -> RecurrenceRule {
        let constraintToCopy = resolveConstraint(ruleTimeUnit)
        let newConstraint = try RecurrenceRuleSetConstraint.init(from: constraintToCopy, setConstraint: values)
        return RecurrenceRule.init(from: self, updatingConstraint: ruleTimeUnit, with: newConstraint)
    }

    private func recurrenceRule(updating ruleTimeUnit: RecurrenceRuleTimeUnit, withRange range: ClosedRange<Int>) throws -> RecurrenceRule {
        let constraintToCopy = resolveConstraint(ruleTimeUnit)
        let newConstraint = try RecurrenceRuleRangeConstraint.init(from: constraintToCopy, rangeConstraint: range)
        return RecurrenceRule.init(from: self, updatingConstraint: ruleTimeUnit, with: newConstraint)
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

    private func isYearConstraintPossible(date: Date) throws -> Bool {
        guard let currentYear = date.year() else {
            throw RecurrenceRuleError.couldNotResolveYearConstraitFromDate
        }

        if yearConstraint.isConstraintActive {
            if let higestPossibleYearValue = yearConstraint.highestPossibleValue {
                if currentYear < higestPossibleYearValue {
                    return true
                }
            } else {
                return true
            }

            return false
        } else {
            return true
        }
    }

}
