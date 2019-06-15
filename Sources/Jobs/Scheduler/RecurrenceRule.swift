import Foundation

enum RecurrenceRuleError: Error {
    case atLeastOneRecurrenceRuleConstraintRequiredToIntialize
    case lowerBoundGreaterThanUpperBound
    case noSetConstraintForRecurrenceRuleTimeUnit
    case couldNotResolveDateComponentValueFromRecurrenceRuleTimeUnit
    case noConstraintsSetForRecurrenceRule
    case coundNotResolveNextInstanceWithin1000Years
    case couldNotResolveYearConstraitFromDate
    case couldNotResloveNextValueFromConstraint
    case ruleInsatiable
    case couldNotParseHourAndMinuteFromString
    case startHourAndMinuteGreaterThanEndHourAndMinute
}

/// Defines the rule for when to run a job based on the given constraints
///
/// - warning: RecurrenceRule only supports the Gregorian calendar (i.e. Calendar.identifier.gregorian or Calendar.identifier.iso8601)
///
/// - Note: RecurrenceRule uses the local TimeZone as default
public struct RecurrenceRule {
    public enum TimeUnit: CaseIterable {
        case second
        case minute
        case hour
        case dayOfWeek
        case dayOfMonth
        case month
        case quarter
        case year
    }

    var timeZone: TimeZone

    private(set) var yearConstraint: YearRecurrenceRuleConstraint?
    private(set) var quarterConstraint: QuarterRecurrenceRuleConstraint?
    private(set) var monthConstraint: MonthRecurrenceRuleConstraint?
    private(set) var dayOfMonthConstraint: DayOfMonthRecurrenceRuleConstraint?
    private(set) var dayOfWeekConstraint: DayOfWeekRecurrenceRuleConstraint?
    private(set) var hourConstraint: HourRecurrenceRuleConstraint?
    private(set) var minuteConstraint: MinuteRecurrenceRuleConstraint?
    private(set) var secondConstraint: SecondRecurrenceRuleConstraint?

    private let timeUnitOrder: [RecurrenceRule.TimeUnit] = [
        .year,
        .quarter,
        .month,
        .dayOfMonth,
        .dayOfWeek,
        .hour,
        .minute,
        .second
    ]

    init(timeZone: TimeZone = TimeZone.current) {
        self.timeZone = timeZone
    }

    init(yearConstraint: YearRecurrenceRuleConstraint? = nil,
         monthConstraint: MonthRecurrenceRuleConstraint? = nil,
         dayOfMonthConstraint: DayOfMonthRecurrenceRuleConstraint? = nil,
         dayOfWeekConstraint: DayOfWeekRecurrenceRuleConstraint? = nil,
         hourConstraint: HourRecurrenceRuleConstraint? = nil,
         minuteConstraint: MinuteRecurrenceRuleConstraint? = nil,
         secondConstraint: SecondRecurrenceRuleConstraint? = nil,
         timeZone: TimeZone = TimeZone.current) throws {
        self.timeZone = timeZone
        self.yearConstraint = yearConstraint
        self.monthConstraint = monthConstraint
        self.dayOfMonthConstraint = dayOfMonthConstraint
        self.dayOfWeekConstraint = dayOfWeekConstraint
        self.hourConstraint = hourConstraint
        self.minuteConstraint = minuteConstraint
        self.secondConstraint = secondConstraint
    }

    public mutating func setYearConstraint(_ yearConstraint: YearRecurrenceRuleConstraint) {
        self.yearConstraint = yearConstraint
    }

    public mutating func setQuarterConstraint(_ quarterConstraint: QuarterRecurrenceRuleConstraint) {
        self.quarterConstraint = quarterConstraint
    }

    public mutating func setMonthConstraint(_ monthConstraint: MonthRecurrenceRuleConstraint) {
        self.monthConstraint = monthConstraint
    }

    public mutating func setDayOfMonthConstraint(_ dayOfMonthConstraint: DayOfMonthRecurrenceRuleConstraint) {
        self.dayOfMonthConstraint = dayOfMonthConstraint
    }

    public mutating func setDayOfWeekConstraint(_ dayOfWeekConstraint: DayOfWeekRecurrenceRuleConstraint) {
        self.dayOfWeekConstraint = dayOfWeekConstraint
    }

    public mutating func setHourConstraint(_ hourConstraint: HourRecurrenceRuleConstraint) {
        self.hourConstraint = hourConstraint
    }

    public mutating func setMinuteConstraint(_ minuteConstraint: MinuteRecurrenceRuleConstraint) {
        self.minuteConstraint = minuteConstraint
    }

    public mutating func setSecondConstraint(_ secondConstraint: SecondRecurrenceRuleConstraint) {
        self.secondConstraint = secondConstraint
    }

    ///  Sets the timeZone used by rule constraintss
    ///
    /// - Parameter timeZone: The TimeZone constraints reference against
    public mutating func usingTimeZone(_ timeZone: TimeZone) {
        self.timeZone = timeZone
    }
}

// RecurrenceRule Evaluation
extension RecurrenceRule {
    /// Finds the next date from the starting date that satisfies the rule
    ///
    /// - Warning: The search is exhausted after the year 3000
    ///
    /// - Parameter date: The starting date
    /// - Returns: The next date that satisfies the rule
    public func resolveNextDateThatSatisfiesRule(date: Date) throws -> Date {
        fatalError("Not Implemented: resolveNextDateThatSatisfiesRule")
    }
}
