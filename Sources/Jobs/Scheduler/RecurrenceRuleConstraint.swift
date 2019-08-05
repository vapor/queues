import Foundation

enum RecurrenceRuleConstraintError: Error {
    case constraintAmountLessThanLowerBound
    case constraintAmountGreaterThanUpperBound
}

internal enum EvaluationState {
    case noComparisonAttempted
    case failed
    case passing
}

internal enum RecurrenceRuleConstraintType {
    case set
    case range
    case step
}

internal protocol RecurrenceRuleConstraintEvaluateable {
    var lowestPossibleValue: Int? { get }
    var highestPossibleValue: Int? { get }

    func evaluate(_ evaluationAmount: Int) -> EvaluationState
    func nextValidValue(currentValue: Int) -> Int?
}

internal protocol RecurrenceRuleConstraint: RecurrenceRuleConstraintEvaluateable {
    var timeUnit: RecurrenceRule.TimeUnit { get }
    var type: RecurrenceRuleConstraintType { get }
    var validLowerBound: Int? { get }
    var validUpperBound: Int? { get }

    static func validate(value: Int, validLowerBound: Int?, validUpperBound: Int?) throws
}

/// default implementation
extension RecurrenceRuleConstraint {
    /// validates a constraint value is within the constraint bounds
    static func validate(value: Int, validLowerBound: Int?, validUpperBound: Int?) throws {
        if let lowerBound = validLowerBound {
            if value < lowerBound {
                throw RecurrenceRuleConstraintError.constraintAmountLessThanLowerBound
            }
        }

        if let upperBound = validUpperBound {
            if value > upperBound {
                throw RecurrenceRuleConstraintError.constraintAmountGreaterThanUpperBound
            }
        }
    }
}

/// A `RecurrenceRuleConstraint` that limits valid values to a given set
/// Equivalent in cron to a single value or list (i.e 14 or 8,3,6,21)
internal struct RecurrenceRuleSetConstraint: RecurrenceRuleConstraint, Equatable {

    let timeUnit: RecurrenceRule.TimeUnit
    let type = RecurrenceRuleConstraintType.set
    let validLowerBound: Int?
    let validUpperBound: Int?
    let setConstraint: Set<Int>

    var lowestPossibleValue: Int? {
        setConstraint.min()
    }

    var highestPossibleValue: Int? {
        setConstraint.max()
    }

    init (timeUnit: RecurrenceRule.TimeUnit, setConstraint: Set<Int> = Set<Int>()) throws {
        self.timeUnit = timeUnit
        self.validLowerBound = Calendar.gregorianLowerBound(for: timeUnit)
        self.validUpperBound = Calendar.gregorianUpperBound(for: timeUnit)

        for amount in setConstraint {
            try Self.validate(value: amount, validLowerBound: validLowerBound, validUpperBound: validUpperBound)
        }
        self.setConstraint = setConstraint
    }

    /// Evaluates if a given amount satisfies the constraint
    ///
    /// - Parameter evaluationAmount: The amount to test
    /// - Returns: passing, failed, or noComparisonAttempted
    internal func evaluate(_ evaluationAmount: Int) -> EvaluationState {
        if setConstraint.contains(evaluationAmount) {
            return EvaluationState.passing
        } else {
            return EvaluationState.failed
        }
    }

    /// Finds the the next value that satisfies the constraint
    ///
    /// - Parameter currentValue: The current value the date component
    /// - Returns: The next value that satisfies the constraint
    internal func nextValidValue(currentValue: Int) -> Int? {
        var lowestValueGreaterThanCurrentValue: Int?

        for value in setConstraint {
            if value >= currentValue {
                if let low = lowestValueGreaterThanCurrentValue {
                    if value < low {
                        lowestValueGreaterThanCurrentValue = value
                    }
                } else {
                    lowestValueGreaterThanCurrentValue = value
                }
            }
        }

        if lowestValueGreaterThanCurrentValue != nil {
            return lowestValueGreaterThanCurrentValue
        } else {
            return lowestPossibleValue
        }
    }
}

/// A `RecurrenceRuleConstraint` that limits valid values to a given range
/// Equivalent in cron to a range of values (i.e 12-6)
internal struct RecurrenceRuleRangeConstraint: RecurrenceRuleConstraint, Equatable {
    let timeUnit: RecurrenceRule.TimeUnit
    let type = RecurrenceRuleConstraintType.range
    let validLowerBound: Int?
    let validUpperBound: Int?
    let rangeConstraint: ClosedRange<Int>

    var lowestPossibleValue: Int? {
        return rangeConstraint.min()
    }

    var highestPossibleValue: Int? {
        return rangeConstraint.max()
    }

    init(timeUnit: RecurrenceRule.TimeUnit, rangeConstraint: ClosedRange<Int>) throws {
        self.timeUnit = timeUnit
        self.validLowerBound = Calendar.gregorianLowerBound(for: timeUnit)
        self.validUpperBound = Calendar.gregorianUpperBound(for: timeUnit)

        try Self.validate(value: rangeConstraint.lowerBound, validLowerBound: validLowerBound, validUpperBound: validUpperBound)
        try Self.validate(value: rangeConstraint.upperBound, validLowerBound: validLowerBound, validUpperBound: validUpperBound)
        self.rangeConstraint = rangeConstraint
    }

    /// Evaluates if a given amount satisfies the constraint
    ///
    /// - Parameter evaluationAmount: The amount to test
    /// - Returns: passing, failed, or noComparisonAttempted
    internal func evaluate(_ evaluationAmount: Int) -> EvaluationState {
        if rangeConstraint.contains(evaluationAmount) {
            return .passing
        } else {
            return .failed
        }
    }

    /// Finds the the next value that satisfies the constraint
    ///
    /// - Parameter currentValue: The current value the date component
    /// - Returns: The next value that satisfies the constraint
    internal func nextValidValue(currentValue: Int) -> Int? {
        var lowestValueGreaterThanCurrentValue: Int?

        if (currentValue + 1) <= rangeConstraint.upperBound {
            if let low = lowestValueGreaterThanCurrentValue {
                if low >= (currentValue + 1) {
                    lowestValueGreaterThanCurrentValue = (currentValue + 1)
                }
            } else {
                lowestValueGreaterThanCurrentValue = (currentValue + 1)
            }
        }

        if lowestValueGreaterThanCurrentValue != nil {
            return lowestValueGreaterThanCurrentValue
        } else {
            return lowestPossibleValue
        }
    }
}

/// A `RecurrenceRuleConstraint` that limits valid values to a given set
/// Equivalent in cron to a step value  (i.e */2)
internal struct RecurrenceRuleStepConstraint: RecurrenceRuleConstraint, Equatable {
    let timeUnit: RecurrenceRule.TimeUnit
    let type = RecurrenceRuleConstraintType.step
    let validLowerBound: Int?
    let validUpperBound: Int?
    let stepConstraint: Int

    var lowestPossibleValue: Int? {
        return 0
    }

    var highestPossibleValue: Int? {
        return nil
    }

    init(timeUnit: RecurrenceRule.TimeUnit, stepConstraint: Int) throws {
        self.timeUnit = timeUnit
        self.validLowerBound = Calendar.gregorianLowerBound(for: timeUnit)
        self.validUpperBound = Calendar.gregorianUpperBound(for: timeUnit)

        if stepConstraint < 1 {
            throw RecurrenceRuleConstraintError.constraintAmountLessThanLowerBound
        }
        if let validUpperBound = validUpperBound {
            if stepConstraint < 1 {
                throw RecurrenceRuleConstraintError.constraintAmountLessThanLowerBound
            }
            if stepConstraint > validUpperBound {
                throw RecurrenceRuleConstraintError.constraintAmountGreaterThanUpperBound
            }
        }

        self.stepConstraint = stepConstraint
    }

    /// Evaluates if a given amount satisfies the constraint
    ///
    /// - Parameter evaluationAmount: The amount to test
    /// - Returns: passing, failed, or noComparisonAttempted
    internal func evaluate(_ evaluationAmount: Int) -> EvaluationState {
        // pass if evaluationAmount is divisiable of stepConstriant
        if evaluationAmount % stepConstraint == 0 {
            return EvaluationState.passing
        } else {
            return EvaluationState.failed
        }
    }

    /// Finds the the next value that satisfies the constraint
    ///
    /// - Parameter currentValue: The current value the date component
    /// - Returns: The next value that satisfies the constraint
    internal func nextValidValue(currentValue: Int) -> Int? {
        var lowestValueGreaterThanCurrentValue: Int?

        // step
        var multiple = 0
        var shouldStopLooking = false

        if let validUpperBound = validUpperBound {
            // others
            var shouldStopLooking = false
            while multiple <= validUpperBound && shouldStopLooking == false {
                if multiple >= currentValue {
                    if let low = lowestValueGreaterThanCurrentValue {
                        if multiple < low {
                            lowestValueGreaterThanCurrentValue = multiple
                        }
                    } else {
                        lowestValueGreaterThanCurrentValue = multiple
                    }
                    shouldStopLooking = true
                }
                multiple = multiple + stepConstraint
            }
        } else {
            // year
            while shouldStopLooking == false {
                if multiple >= currentValue {
                    if let low = lowestValueGreaterThanCurrentValue {
                        if multiple < low {
                            lowestValueGreaterThanCurrentValue = multiple
                        }
                    } else {
                        lowestValueGreaterThanCurrentValue = multiple
                    }
                    shouldStopLooking = true
                }

                multiple = multiple + stepConstraint
            }
        }

        return lowestValueGreaterThanCurrentValue ?? lowestPossibleValue
    }

}
