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
    // year (1970-3000)
    // quarter (1-4)
    // month (1-12) ex: 1 is January, 12 is December
    // weekOfYear (1-52)
    // weekOfMonth (1-5)
    // dayOfMonth (1-31) ex: 1 is the 1st of month, 31 is the 31st of month
    // dayOfWeek (1-7) ex: 1 sunday, 7 saturday
    // hour (0-23)
    // minute (0-59)
    // second (0-59)
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

        ruleTimeUnit == .year ? (self.yearConstraint = newConstraint) : (self.yearConstraint = ruleToCopy.yearConstraint)
        ruleTimeUnit == .quarter ? (self.quarterConstraint = newConstraint) : (self.quarterConstraint = ruleToCopy.quarterConstraint)
        ruleTimeUnit == .month ? (self.monthConstraint = newConstraint) : (self.monthConstraint = ruleToCopy.monthConstraint)
        ruleTimeUnit == .weekOfYear ? (self.weekOfYearConstraint = newConstraint) : (self.weekOfYearConstraint = ruleToCopy.weekOfYearConstraint)
        ruleTimeUnit == .weekOfMonth ? (self.weekOfMonthConstraint = newConstraint) : (self.weekOfMonthConstraint = ruleToCopy.weekOfMonthConstraint)
        ruleTimeUnit == .dayOfMonth ? (self.dayOfMonthConstraint = newConstraint) : (self.dayOfMonthConstraint = ruleToCopy.dayOfMonthConstraint)
        ruleTimeUnit == .dayOfWeek ? (self.dayOfWeekConstraint = newConstraint) : (self.dayOfWeekConstraint = ruleToCopy.dayOfWeekConstraint)
        ruleTimeUnit == .hour ? (self.hourConstraint = newConstraint) : (self.hourConstraint = ruleToCopy.hourConstraint)
        ruleTimeUnit == .minute ? (self.minuteConstraint = newConstraint) : (self.minuteConstraint = ruleToCopy.minuteConstraint)
        ruleTimeUnit == .second ? (self.secondConstraint = newConstraint) : (self.secondConstraint = ruleToCopy.secondConstraint)
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

    ///  Sets the timeZone that the constraints are based off of
    ///
    /// - Parameter timeZone: The TimeZone constraints reference against
    public func usingTimeZone(_ timeZone: TimeZone) throws -> RecurrenceRule {
        return RecurrenceRule.init(from: self, updatingTimeZone: timeZone)
    }

    // step
    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. For example for every(.minutes(22)).atHours([4, 5]) the minute constraint will
    ///         be satisfied at: 04:00, 04:22, 04:44, 05:00, 05:22, and 05:44
    ///
    /// - Parameter timeAmount: timeAmount to be scheduled
    public func every(_ timeAmount: ScheduleTimeAmount) throws -> RecurrenceRule {
        let ruleTimeUnit = resolveRuleTimeUnit(from: timeAmount.timeUnit)
        let constraintToCopy = resolveConstraint(ruleTimeUnit)
        let newConstraint = try RecurrenceRuleStepConstraint.init(from: constraintToCopy, stepConstraint: timeAmount.amount)
        return RecurrenceRule.init(from: self, updatingConstraint: ruleTimeUnit, with: newConstraint)
    }

    // step convenience
    // second
    public func everySecond() throws -> RecurrenceRule {
        return try every(.seconds(1))
    }

    public func everyFiveSeconds() throws -> RecurrenceRule {
        return try every(.seconds(5))
    }

    public func everyTenSeconds() throws -> RecurrenceRule {
        return try every(.seconds(10))
    }

    public func everyFifteenSeconds() throws -> RecurrenceRule {
        return try every(.seconds(15))
    }

    public func every30Seconds() throws -> RecurrenceRule {
        return try every(.seconds(30))
    }

    // minute
    public func everyMinute() throws -> RecurrenceRule {
        return try every(.minutes(1))
    }

    public func everyFiveMinutes() throws -> RecurrenceRule {
        return try every(.minutes(5))
    }

    public func everyTenMinutes() throws -> RecurrenceRule {
        return try every(.minutes(10))
    }

    public func everyFifteenMinutes() throws -> RecurrenceRule {
        return try every(.minutes(15))
    }

    public func every30Minutes() throws -> RecurrenceRule {
        return try every(.minutes(30))
    }

    // hour
    public func hourly() throws -> RecurrenceRule {
        return try every(.hours(1))
    }

    // dayOfWeek
    public func weekly() throws -> RecurrenceRule {
        return try every(.daysOfWeek(1))
    }

    public func weekly(onDayOfWeek dayOfWeek: Int) throws -> RecurrenceRule {
         return try every(.daysOfWeek(dayOfWeek))
    }

    // dayOfMonth
    public func daily() throws -> RecurrenceRule {
        return try every(.days(1))
    }

    // quarter
    public func quarterly() throws -> RecurrenceRule {
        return try every(.quarters(1))
    }

    // year
    public func yearly() throws -> RecurrenceRule {
        return try every(.days(1))
    }

    /// The second that will satisfy the rule pending all other constraints are met
    ///
    /// - Parameter second: Lower bound: 0, Upper bound: 59
    public func atSecond(_ second: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .second, withValue: second)
    }

    /// The minute that will satisfy the rule pending all other constraints are met
    ///
    /// - Parameter minute: Lower bound: 0, Upper bound: 59
    public func atMinute(_ minute: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .minute, withValue: minute)
    }

    /// The hour that will satisfy the rule pending all other constraints are met
    ///
    /// - Parameter hour: Lower bound: 0, Upper bound: 23
    public func atHour(_ hour: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .hour, withValue: hour)
    }

    /// The dayOfWeek that will satisfy the rule pending all other constraints are met
    ///
    /// - Note: 1 is Sunday, 7 is Saturday
    /// - Parameter dayOfWeek: Lower bound: 1, Upper bound: 7
    public func atDayOfWeek(_ dayOfWeek: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .dayOfWeek, withValue: dayOfWeek)
    }

    /// The dayOfMonth that will satisfy the rule pending all other constraints are met
    ///
    /// - Parameter dayOfMonth: Lower bound: 1, Upper bound: 31
    public func atDayOfMonth(_ dayOfMonth: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .dayOfMonth, withValue: dayOfMonth)
    }

    /// The weekOfMonth that will satisfy the rule pending all other constraints are met
    ///
    /// - Parameter dayOfMonth: Lower bound: 1, Upper bound: 5
    public func atWeekOfMonth(_ weekOfMonth: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .weekOfMonth, withValue: weekOfMonth)
    }

    /// The weekOfYear that will satisfy the rule pending all other constraints are met
    ///
    /// - Parameter weekOfYear: Lower bound: 1, Upper bound: 52
    public func atWeekOfYear(_ weekOfYear: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .weekOfYear, withValue: weekOfYear)
    }

    /// The month that will satisfy the rule pending all other constraints are met
    ///
    /// - Note: 1 is January, 12 is December
    /// - Parameter month: Lower bound: 1, Upper bound: 12
    public func atMonth(_ month: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .month, withValue: month)
    }

    /// The quarter that will satisfy the rule pending all other constraints are met
    ///
    /// - Parameter year: Lower bound: 1, Upper bound: 4
    public func atQuarter(_ quarter: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .quarter, withValue: quarter)
    }

    /// The year that will satisfy the rule pending all other constraints are met
    ///
    /// - Parameter year: Lower bound: 1970, Upper bound: 3000
    public func atYear(_ year: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .year, withValue: year)
    }

    // conveniene methods for set
    public func sundays() throws -> RecurrenceRule {
        return try atDayOfWeek(1)
    }

    public func mondays() throws -> RecurrenceRule {
        return try atDayOfWeek(2)
    }

    public func tuesdays() throws -> RecurrenceRule {
        return try atDayOfWeek(3)
    }

    public func wednesdays() throws -> RecurrenceRule {
        return try atDayOfWeek(4)
    }

    public func thursdays() throws -> RecurrenceRule {
        return try atDayOfWeek(5)
    }

    public func fridays() throws -> RecurrenceRule {
        return try atDayOfWeek(6)
    }

    public func saturdays() throws -> RecurrenceRule {
        return try atDayOfWeek(7)
    }

    public func weekdays() throws -> RecurrenceRule {
        return try atDaysOfWeek([2, 3, 4, 5, 6])
    }

    public func weekends() throws -> RecurrenceRule {
        return try atDaysOfWeek([1, 7])
    }

    // add array to set
    public func atSeconds(_ seconds: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .second, withValues: seconds)
    }

    public func atMinutes(_ minutes: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .minute, withValues: minutes)
    }

    public func atHours(_ hours: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .hour, withValues: hours)
    }

    public func atDaysOfWeek(_ daysOfWeek: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .dayOfWeek, withValues: daysOfWeek)
    }

    public func atDaysOfMonth(_ daysOfMonth: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .dayOfMonth, withValues: daysOfMonth)
    }

    public func atWeeksOfMonth(_ weeksOfMonth: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .weekOfMonth, withValues: weeksOfMonth)
    }

    public func atWeeksOfYear(_ weeksOfYear: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .weekOfYear, withValues: weeksOfYear)
    }

    public func atMonths(_ months: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .month, withValues: months)
    }

    public func atQuarters(_ quarters: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .quarter, withValues: quarters)
    }

    public func atYears(_ years: Set<Int>) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .year, withValues: years)
    }

    // ranges
    public func whenSecondInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .second, withRange: lowerBound...upperBound)
    }

    public func whenMinuteInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .minute, withRange: lowerBound...upperBound)
    }

    public func whenHourInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .hour, withRange: lowerBound...upperBound)
    }

    public func whenDayOfWeekInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .dayOfWeek, withRange: lowerBound...upperBound)
    }

    public func whenDayOfMonthInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .dayOfMonth, withRange: lowerBound...upperBound)
    }

    public func whenMonthInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .month, withRange: lowerBound...upperBound)
    }

    public func whenQuarterInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .quarter, withRange: lowerBound...upperBound)
    }

    public func whenYearInRange(lowerBound: Int, upperBound: Int) throws -> RecurrenceRule {
        return try recurrenceRule(updating: .year, withRange: lowerBound...upperBound)
    }

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

    private func resolveRuleTimeUnit(from scheduleTimeUnit: ScheduleTimeUnit) -> RecurrenceRuleTimeUnit {
        switch scheduleTimeUnit {
        case .second:
            return RecurrenceRuleTimeUnit.second
        case .minute:
            return RecurrenceRuleTimeUnit.minute
        case .hour:
            return RecurrenceRuleTimeUnit.hour
        case .dayOfWeek:
            return RecurrenceRuleTimeUnit.dayOfWeek
        case .day:
            return RecurrenceRuleTimeUnit.dayOfMonth
        case .week:
            return RecurrenceRuleTimeUnit.weekOfYear
        case .month:
            return RecurrenceRuleTimeUnit.month
        case .quarter:
            return RecurrenceRuleTimeUnit.quarter
        case .year:
            return RecurrenceRuleTimeUnit.year
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
