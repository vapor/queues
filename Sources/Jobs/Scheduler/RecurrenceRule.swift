import Foundation

enum RecurrenceRuleError: Error {
    case atLeastOneRecurrenceRuleConstraintRequiredToIntialize
    case lowerBoundGreaterThanUpperBound
    case noSetConstraintForRecurrenceRuleTimeUnit
    case couldNotResolveDateComponentValueFromRecurrenceRuleTimeUnit
    case noConstraintsSetForRecurrenceRule
    case coundNotResolveNextInstanceWithin1000Years
    case couldNotResolveYearComponentValueFromDate
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
internal struct RecurrenceRule {
    internal enum TimeUnit: CaseIterable {
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

    internal mutating func setYearConstraint(_ yearConstraint: YearRecurrenceRuleConstraint) {
        self.yearConstraint = yearConstraint
    }

    internal mutating func setQuarterConstraint(_ quarterConstraint: QuarterRecurrenceRuleConstraint) {
        self.quarterConstraint = quarterConstraint
    }

    internal mutating func setMonthConstraint(_ monthConstraint: MonthRecurrenceRuleConstraint) {
        self.monthConstraint = monthConstraint
    }

    internal mutating func setDayOfMonthConstraint(_ dayOfMonthConstraint: DayOfMonthRecurrenceRuleConstraint) {
        self.dayOfMonthConstraint = dayOfMonthConstraint
    }

    internal mutating func setDayOfWeekConstraint(_ dayOfWeekConstraint: DayOfWeekRecurrenceRuleConstraint) {
        self.dayOfWeekConstraint = dayOfWeekConstraint
    }

    internal mutating func setHourConstraint(_ hourConstraint: HourRecurrenceRuleConstraint) {
        self.hourConstraint = hourConstraint
    }

    internal mutating func setMinuteConstraint(_ minuteConstraint: MinuteRecurrenceRuleConstraint) {
        self.minuteConstraint = minuteConstraint
    }

    internal mutating func setSecondConstraint(_ secondConstraint: SecondRecurrenceRuleConstraint) {
        self.secondConstraint = secondConstraint
    }

    ///  Sets the timeZone used by rule constraintss
    ///
    /// - Parameter timeZone: The TimeZone constraints reference against
    internal mutating func usingTimeZone(_ timeZone: TimeZone) {
        self.timeZone = timeZone
    }
}

/// Extension for the evaluation of a `RecurrenceRule`s
extension RecurrenceRule {
    internal struct EvaluationResult {
        /// Set to true if the date satisfies the `RecurrenceRule`
        let isValid: Bool

        /// The `RecurrenceRule.TimeUnit` associated with the highest failing constraint
        let timeUnitFailedOn: RecurrenceRule.TimeUnit?

        init(isValid: Bool, timeUnitFailedOn: RecurrenceRule.TimeUnit?) {
            self.isValid = isValid
            self.timeUnitFailedOn = timeUnitFailedOn
        }
    }

    /// Evaluates if the constraints are satified at a given date
    ///
    /// - Parameter date: The date to test the constraints against
    /// - Returns: returns true if all constraints are satisfied for the given date
    public func evaluate(date: Date) throws -> Bool {
        return try evaluate(date: date).isValid
    }

    /// Evaluate  the `RecurrenceRule`'s constraints to deterine it they are satisfied
    ///
    /// - NOTE: Upon an evaluation result of false the `timeUnitFailedOn` property of `RecurrenceRule.EvaluationResult`
    /// is always set to `RecurrenceRule.TimeUnit` of the highest failing constraint so that it's associated date component value can
    /// be advanced first. This impoves the efficiency when finding the next date that satisfies the `RecurrenceRule`
    private func evaluate(date: Date) throws -> RecurrenceRule.EvaluationResult {
        var ruleEvaluationState = EvaluationState.noComparisonAttempted
        var ruleTimeUnitFailedOn: RecurrenceRule.TimeUnit?

        for ruleTimeUnit in timeUnitOrder {
            guard let dateComponentValue = date.dateComponentValue(for: ruleTimeUnit, atTimeZone: timeZone) else {
                throw RecurrenceRuleError.couldNotResolveDateComponentValueFromRecurrenceRuleTimeUnit
            }

            if let specificConstraint = resolveSpecificConstraint(ruleTimeUnit) {
                // evaluates the constraint
                let constraintEvalutionState = specificConstraint.evaluate(dateComponentValue)

                if constraintEvalutionState != .noComparisonAttempted {
                    ruleEvaluationState = constraintEvalutionState
                }
            } else {
                // constraint not set
                let lowestCadence = resolveLowestCadence()
                let lowestCadenceLevel = resolveCadenceLevel(lowestCadence)
                let currentConstraintCadenceLevel = resolveCadenceLevel(ruleTimeUnit)

                /// If second, minute, hour, dayOfMonth or month constraints are not set
                /// they must be at their default values to avoid the rule passing on every second
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
            return EvaluationResult(isValid: true, timeUnitFailedOn: nil)
        } else {
            return EvaluationResult(isValid: false, timeUnitFailedOn: ruleTimeUnitFailedOn)
        }
    }

    /// Finds the next date from the starting date that satisfies the rule
    ///
    /// - Warning: The search is exhausted after the year 3000
    ///
    /// - Parameter currentDate: The starting date, a date after this will be searched for
    /// - Returns: The next date that satisfies the rule
    internal func resolveNextDateThatSatisfiesRule(currentDate: Date) throws -> Date {
        guard let timeUnitOfLowestActiveConstraint = resolveTimeUnitOfActiveConstraintWithLowestCadenceLevel() else {
            throw RecurrenceRuleError.noConstraintsSetForRecurrenceRule
        }

        /// Defines a year when to stop searching
        guard let currentYear = currentDate.year() else {
            throw RecurrenceRuleError.couldNotResolveYearComponentValueFromDate
        }
        let exhaustedYear = currentYear + 1000

        /// Throws an error if rule contains constraints that can never be satisfied
        try checkForInsatiableConstraints()

        /// Increments the `RecurrenceRule.TimeUnit` of the lowest active constraint so that
        /// the currentDate will not be returned (The result must be some date after the currentDate parameter)
        var dateToTest = try currentDate.dateByIncrementing(timeUnitOfLowestActiveConstraint, atTimeZone: timeZone)

        var isNextInstanceFound = false
        var isSearchExhausted = false
        var numOfChecksMade = 0
        while isNextInstanceFound == false && isSearchExhausted == false {
            /// Evaluates if the dateToTest satisifes the` RecurrenceRule`. If the dateToTest does not satisfy the `RecurrenceRule`
            /// the associated date component value of the `SpecificRecurrenceRuleConstraint`that failed is advanced.
            /// For example if ruleTimeUnitFailedOn equals `.hour`, the hour component of dateToTest is advanced to the next valid value.
            if let ruleTimeUnitFailedOn = try self.evaluate(date: dateToTest).timeUnitFailedOn {

                /// Advances the associated date component value of the failed `RecurrenceRuel.TimeUnit` to the next valid value
                /// as defined by the SpecificRecurrenceRuleConstraint
                let nextValidValue = try resolveNextValidValue(for: ruleTimeUnitFailedOn, date: dateToTest)
                dateToTest = try dateToTest.nextDate(where: ruleTimeUnitFailedOn, is: nextValidValue, atTimeZone: timeZone)

                /// Search is exhausted if the year component of dateToTest is greater than the exhaustedYear
                if let year = dateToTest.year() {
                    if year > exhaustedYear {
                        isSearchExhausted = true
                    }
                } else {
                    throw RecurrenceRuleError.couldNotResolveYearComponentValueFromDate
                }
                numOfChecksMade += 1
            } else {
                isNextInstanceFound = true
            }
        }

        if isNextInstanceFound {
            return dateToTest
        } else {
            throw RecurrenceRuleError.coundNotResolveNextInstanceWithin1000Years
        }
    }

    /// Throws error if rule contains constraints that can never be satisfiedss
    private func checkForInsatiableConstraints() throws {
        // January, March, May, July, August, October, December
        let monthsWithExactly31Days = [1, 3, 5, 7, 8, 10, 12]
        // April, June, September, November
        let monthsWithExactly30Days = [4, 6, 9, 11]
        // februrary has 28 or 29 days
        guard let dayOfMonthLowestPossibleValue = dayOfMonthConstraint?.lowestPossibleValue else {
            return
        }

        if dayOfMonthLowestPossibleValue > 30 {
            var hasAtLeastOneMonthWith31Days = false
            if let monthConstraint = monthConstraint {
                for month in monthsWithExactly31Days {
                    if monthConstraint.evaluate(month) == .passing {
                        hasAtLeastOneMonthWith31Days = true
                    }
                }
            }

            if hasAtLeastOneMonthWith31Days == false {
                throw RecurrenceRuleError.ruleInsatiable
            }
        } else if dayOfMonthLowestPossibleValue > 29 {
            var hasOneMonthWithAtLeast30Days = false

            if let monthConstraint = monthConstraint {
                for month in monthsWithExactly31Days {
                    if monthConstraint.evaluate(month) == .passing {
                        hasOneMonthWithAtLeast30Days = true
                    }
                }
                for month in monthsWithExactly30Days {
                    if monthConstraint.evaluate(month) == .passing {
                        hasOneMonthWithAtLeast30Days = true
                    }
                }
            }

            if hasOneMonthWithAtLeast30Days == false {
                throw RecurrenceRuleError.ruleInsatiable
            }
        }
    }

    private func resolveTimeUnitOfActiveConstraintWithLowestCadenceLevel() -> RecurrenceRule.TimeUnit? {
        var activeConstraintTimeUnitWithLowestCadenceLevel: RecurrenceRule.TimeUnit?

        for ruleTimeUnit in timeUnitOrder {
            let constraint = resolveSpecificConstraint(ruleTimeUnit)
            if constraint != nil {
                activeConstraintTimeUnitWithLowestCadenceLevel = ruleTimeUnit
            }
        }

        return activeConstraintTimeUnitWithLowestCadenceLevel
    }

    /// Finds the the next valid value for the constraint given the current date
    private func resolveNextValidValue(for ruleTimeUnit: RecurrenceRule.TimeUnit, date: Date) throws -> Int {
        guard let currentValue = date.dateComponentValue(for: ruleTimeUnit, atTimeZone: timeZone) else {
            throw RecurrenceRuleError.couldNotResolveDateComponentValueFromRecurrenceRuleTimeUnit
        }

        if let specificConstraint = resolveSpecificConstraint(ruleTimeUnit) {

            var nextValidValue: Int?
            // if dayOfMonth constraint and dayOfMonth constarint is in effect, return value for last dayOfMonth
            if isLastDayOfMonthConstraint(specificConstraint) {
                if try date.isLastDayOfMonth() {
                    return 0
                } else {
                    nextValidValue = date.numberOfDaysInMonth()
                }
            } else {
                nextValidValue = specificConstraint.nextValidValue(currentValue: currentValue)
            }

            guard let nextValue = nextValidValue else {
                throw RecurrenceRuleError.couldNotResloveNextValueFromConstraint
            }

            return nextValue
        } else {
            throw RecurrenceRuleError.couldNotResloveNextValueFromConstraint
        }
    }

    private func isLastDayOfMonthConstraint(_ specificConstraint: SpecificRecurrenceRuleConstraint) -> Bool {
        if specificConstraint._constraint.timeUnit == .dayOfMonth {
            if let dayOfMonthSpecificConstraint = specificConstraint as? DayOfMonthRecurrenceRuleConstraint {
                return dayOfMonthSpecificConstraint.isLimitedToLastDayOfMonth
            }
        }
        return false
    }

    // get a specificConstraint by its RecurrenceRule.TimeUnit
    private func resolveSpecificConstraint(_ ruleTimeUnit: RecurrenceRule.TimeUnit) -> SpecificRecurrenceRuleConstraint? {
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
            case .month:
                return self.monthConstraint
            case .quarter:
                return self.quarterConstraint
            case .year:
                return self.yearConstraint
        }
    }

    private func resolveLowestCadence() -> RecurrenceRule.TimeUnit {
        if secondConstraint != nil {
            return .second
        } else if minuteConstraint != nil {
            return .minute
        } else if hourConstraint != nil {
            return .hour
        } else if dayOfMonthConstraint != nil {
            return .dayOfMonth
        } else if monthConstraint != nil {
            return .month
        } else {
            return .year
        }
    }

    private func resolveCadenceLevel(_ ruleTimeUnit: RecurrenceRule.TimeUnit) -> Int {
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
                return 5
        }
    }
}
