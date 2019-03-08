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
public class RecurrenceRule {
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
    let secondConstraint: RecurrenceRuleConstraint

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

    init() throws {
        yearConstraint = RecurrenceRuleConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .year),
                                                       validUpperBound: try Calendar.current.upperBound(for: .year))
        quarterConstraint = RecurrenceRuleConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .quarter),
                                                       validUpperBound: try Calendar.current.upperBound(for: .quarter))
        monthConstraint = RecurrenceRuleConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .month),
                                                          validUpperBound: try Calendar.current.upperBound(for: .month))
        weekOfYearConstraint = RecurrenceRuleConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .weekOfYear),
                                                          validUpperBound: try Calendar.current.upperBound(for: .weekOfYear))
        weekOfMonthConstraint = RecurrenceRuleConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .weekOfMonth),
                                                          validUpperBound: try Calendar.current.upperBound(for: .weekOfMonth))
        dayOfMonthConstraint = RecurrenceRuleConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .dayOfMonth),
                                                          validUpperBound: try Calendar.current.upperBound(for: .dayOfMonth))
        dayOfWeekConstraint = RecurrenceRuleConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .dayOfWeek),
                                                          validUpperBound: try Calendar.current.upperBound(for: .dayOfWeek))
        hourConstraint = RecurrenceRuleConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .hour),
                                                            validUpperBound: try Calendar.current.upperBound(for: .hour))
        minuteConstraint = RecurrenceRuleConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .minute),
                                                            validUpperBound: try Calendar.current.upperBound(for: .minute))
        secondConstraint = RecurrenceRuleConstraint.init(validLowerBound: try Calendar.current.lowerBound(for: .second),
                                                            validUpperBound: try Calendar.current.upperBound(for: .second))
    }

    ///  Sets timeZone to constraints are based off of
    ///
    /// - Parameter timeZone: The TimeZone constraints reference against
    public func usingTimeZone(_ timeZone: TimeZone) -> Self {
        self.timeZone = timeZone
        return self
    }

    // step
    /// Defines the step value of a constraint
    ///
    /// - Note: inputed values are step values. For example for every(.minutes(22)).atHours([4, 5]) the minute constraint will
    ///         be satisfied at: 04:00, 04:22, 04:44, 05:00, 05:22, and 05:44
    ///
    /// - Parameter timeAmount: timeAmount to be scheduled
    public func every(_ timeAmount: ScheduleTimeAmount) throws -> Self {
        switch timeAmount.timeUnit {
        case .second:
            try secondConstraint.setStep(timeAmount.amount)
        case .minute:
            try minuteConstraint.setStep(timeAmount.amount)
        case .hour:
            try hourConstraint.setStep(timeAmount.amount)
        case .dayOfWeek:
            try dayOfWeekConstraint.setStep(timeAmount.amount)
        case .day:
            try dayOfWeekConstraint.setStep(timeAmount.amount)
        case .week:
            try weekOfMonthConstraint.setStep(timeAmount.amount)
        case .month:
            try monthConstraint.setStep(timeAmount.amount)
        case .quarter:
            try quarterConstraint.setStep(timeAmount.amount)
        case .year:
            try yearConstraint.setStep(timeAmount.amount)
        }

        return self
    }

    // step convenience
    // second
    public func everySecond() throws -> Self {
        return try every(.seconds(1))
    }

    public func everyFiveSeconds() throws -> Self {
        return try every(.seconds(5))
    }

    public func everyTenSeconds() throws -> Self {
        return try every(.seconds(10))
    }

    public func everyFifteenSeconds() throws -> Self {
        return try every(.seconds(15))
    }

    public func every30Seconds() throws -> Self {
        return try every(.seconds(30))
    }

    // minute
    public func everyMinute() throws -> Self {
        return try every(.minutes(1))
    }

    public func everyFiveMinutes() throws -> Self {
        return try every(.minutes(5))
    }

    public func everyTenMinutes() throws -> Self {
        return try every(.minutes(10))
    }

    public func everyFifteenMinutes() throws -> Self {
        return try every(.minutes(15))
    }

    public func every30Minutes() throws -> Self {
        return try every(.minutes(30))
    }

    // hour
    public func hourly() throws -> Self {
        return try every(.hours(1))
    }

    // dayOfWeek
    public func weekly() throws -> Self {
        return try every(.daysOfWeek(1))
    }

    public func weekly(onDayOfWeek dayOfWeek: Int) throws -> Self {
         return try every(.daysOfWeek(dayOfWeek))
    }

    // dayOfMonth
    public func daily() throws -> Self {
        return try every(.days(1))
    }

    // quarter
    public func quarterly() throws -> Self {
        return try every(.quarters(1))
    }

    // year
    public func yearly() throws -> Self {
        return try every(.days(1))
    }

    /// The second that will satisfy the rule pending all other constraints are met
    ///
    /// - Parameter second: Lower bound: 0, Upper bound: 59
    public func atSecond(_ second: Int) throws -> Self {
        try secondConstraint.addToSet(second)
        return self
    }

    /// The minute that will satisfy the rule pending all other constraints are met
    ///
    /// - Parameter minute: Lower bound: 0, Upper bound: 59
    public func atMinute(_ minute: Int) throws -> Self {
        try minuteConstraint.addToSet(minute)
        return self
    }

    /// The hour that will satisfy the rule pending all other constraints are met
    ///
    /// - Parameter hour: Lower bound: 0, Upper bound: 23
    public func atHour(_ hour: Int) throws -> Self {
        try hourConstraint.addToSet(hour)
        return self
    }

    /// The dayOfWeek that will satisfy the rule pending all other constraints are met
    ///
    /// - Note: 1 is Sunday, 7 is Saturday
    /// - Parameter dayOfWeek: Lower bound: 1, Upper bound: 7
    public func atDayOfWeek(_ dayOfWeek: Int) throws -> Self {
        try dayOfWeekConstraint.addToSet(dayOfWeek)
        return self
    }

    /// The dayOfMonth that will satisfy the rule pending all other constraints are met
    ///
    /// - Parameter dayOfMonth: Lower bound: 1, Upper bound: 31
    public func atDayOfMonth(_ dayOfMonth: Int) throws -> Self {
        try dayOfMonthConstraint.addToSet(dayOfMonth)
        return self
    }

    /// The weekOfMonth that will satisfy the rule pending all other constraints are met
    ///
    /// - Parameter dayOfMonth: Lower bound: 1, Upper bound: 5
    public func atWeekOfMonth(_ weekOfMonth: Int) throws -> Self {
        try weekOfMonthConstraint.addToSet(weekOfMonth)
        return self
    }

    /// The weekOfYear that will satisfy the rule pending all other constraints are met
    ///
    /// - Parameter weekOfYear: Lower bound: 1, Upper bound: 52
    public func atWeekOfYear(_ weekOfYear: Int) throws -> Self {
        try weekOfYearConstraint.addToSet(weekOfYear)
        return self
    }

    /// The month that will satisfy the rule pending all other constraints are met
    ///
    /// - Note: 1 is January, 12 is December
    /// - Parameter month: Lower bound: 1, Upper bound: 12
    public func atMonth(_ month: Int) throws -> Self {
        try monthConstraint.addToSet(month)
        return self
    }

    /// The quarter that will satisfy the rule pending all other constraints are met
    ///
    /// - Parameter year: Lower bound: 1, Upper bound: 4
    public func atQuarter(_ quarter: Int) throws -> Self {
        try quarterConstraint.addToSet(quarter)
        return self
    }

    /// The year that will satisfy the rule pending all other constraints are met
    ///
    /// - Parameter year: Lower bound: 1970, Upper bound: 3000
    public func atYear(_ year: Int) throws -> Self {
        try yearConstraint.addToSet(year)
        return self
    }

    // conveniene methods for set
    public func sundays() throws -> Self {
        return try atDayOfWeek(1)
    }

    public func mondays() throws -> Self {
        return try atDayOfWeek(2)
    }

    public func tuesdays() throws -> Self {
        return try atDayOfWeek(3)
    }

    public func wednesdays() throws -> Self {
        return try atDayOfWeek(4)
    }

    public func thursdays() throws -> Self {
        return try atDayOfWeek(5)
    }

    public func fridays() throws -> Self {
        return try atDayOfWeek(6)
    }

    public func saturdays() throws -> Self {
        return try atDayOfWeek(7)
    }

    public func weekdays() throws -> Self {
        return try atDaysOfWeek([2, 3, 4, 5, 6])
    }

    public func weekends() throws -> Self {
        return try atDaysOfWeek([1, 7])
    }

    // add array to set
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

    public func atWeeksOfMonth(_ weeksOfMonth: [Int]) throws -> Self {
        try weekOfMonthConstraint.addToSet(weeksOfMonth)
        return self
    }

    public func atWeeksOfYear(_ weeksOfYear: [Int]) throws -> Self {
        try weekOfYearConstraint.addToSet(weeksOfYear)
        return self
    }

    public func atMonths(_ months: [Int]) throws -> Self {
        try monthConstraint.addToSet(months)
        return self
    }

    public func atQuarters(_ quarters: [Int]) throws -> Self {
        try quarterConstraint.addToSet(quarters)
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

    private func isYearConstraintPossible(date: Date) throws -> Bool {
        guard let currentYear = date.year() else {
            throw RecurrenceRuleError.couldNotResolveYearConstraitFromDate
        }

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

}
