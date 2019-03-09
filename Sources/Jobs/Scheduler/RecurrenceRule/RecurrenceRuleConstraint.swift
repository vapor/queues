import Foundation

enum RecurrenceRuleConstraintError: Error {
    case constraintAmountLessThanLowerBound
    case constraintAmountGreaterThanUpperBound
}

struct ConstraintValueValidator {
    func validate(value: Int, validLowerBound: Int?, validUpperBound: Int?) throws {
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

protocol RecurrenceRuleConstraint {
    var validLowerBound: Int? { get }
    var validUpperBound: Int? { get }
    var lowestPossibleValue: Int? { get }
    var highestPossibleValue: Int? { get }
    var isConstraintActive: Bool { get }

    func evaluate(_ evaluationAmount: Int) -> EvaluationState
    func nextValidValue(currentValue: Int) -> Int?
}

struct RecurrenceRuleSetConstraint: RecurrenceRuleConstraint {
    let validLowerBound: Int?
    let validUpperBound: Int?
    let setConstraint: Set<Int>

    var lowestPossibleValue: Int? {
        if var lowest = setConstraint.first {
            for value in setConstraint {
                if value < lowest {
                    lowest = value
                }
            }
            return lowest
        } else {
            return nil
        }
    }

    var highestPossibleValue: Int? {
        if var highest = setConstraint.first {
            for value in setConstraint {
                if value > highest {
                    highest = value
                }
            }
            return highest
        } else {
            return nil
        }
    }

    var isConstraintActive: Bool {
        if setConstraint.isEmpty {
            return false
        } else {
            return true
        }
    }

    init(validLowerBound: Int?, validUpperBound: Int?) {
        self.validLowerBound = validLowerBound
        self.validUpperBound = validUpperBound
        self.setConstraint = Set<Int>()
    }

    init(validLowerBound: Int?, validUpperBound: Int?, setConstraint: Set<Int> = Set<Int>()) throws {
        self.validLowerBound = validLowerBound
        self.validUpperBound = validUpperBound

        let validator = ConstraintValueValidator()
        for amount in setConstraint {
            try validator.validate(value: amount, validLowerBound: validLowerBound, validUpperBound: validUpperBound)
        }
        self.setConstraint = setConstraint
    }

    init(from constraintToCopy: RecurrenceRuleConstraint, setConstraint: Set<Int> = Set<Int>()) throws {
        self.validLowerBound = constraintToCopy.validLowerBound
        self.validUpperBound = constraintToCopy.validUpperBound

        let validator = ConstraintValueValidator()
        for amount in setConstraint {
            try validator.validate(value: amount, validLowerBound: validLowerBound, validUpperBound: validUpperBound)
        }
        self.setConstraint = setConstraint
    }

    func evaluate(_ evaluationAmount: Int) -> EvaluationState {
        if isConstraintActive == false {
            return EvaluationState.noComparisonAttempted
        }

        if setConstraint.contains(evaluationAmount) {
            return EvaluationState.passing
        } else {
            return EvaluationState.failed
        }
    }

    func nextValidValue(currentValue: Int) -> Int? {
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

struct RecurrenceRuleRangeConstraint: RecurrenceRuleConstraint {
    let validLowerBound: Int?
    let validUpperBound: Int?
    let rangeConstraint: ClosedRange<Int>?

    var lowestPossibleValue: Int? {
        if let range = rangeConstraint {
            return range.lowerBound
        } else {
            return nil
        }
    }

    var highestPossibleValue: Int? {
        if let range = rangeConstraint {
            return range.upperBound
        } else {
            return nil
        }
    }

    var isConstraintActive: Bool {
        if rangeConstraint == nil {
            return false
        } else {
            return true
        }
    }

    init(validLowerBound: Int?, validUpperBound: Int?) {
        self.validLowerBound = validLowerBound
        self.validUpperBound = validUpperBound
        self.rangeConstraint = nil
    }

    init(validLowerBound: Int?, validUpperBound: Int?, rangeConstraint: ClosedRange<Int>? = nil) throws {
        self.validLowerBound = validLowerBound
        self.validUpperBound = validUpperBound

        if let range = rangeConstraint {
            let validator = ConstraintValueValidator()
            try validator.validate(value: range.lowerBound, validLowerBound: validLowerBound, validUpperBound: validUpperBound)
            try validator.validate(value: range.upperBound, validLowerBound: validLowerBound, validUpperBound: validUpperBound)
        }
        self.rangeConstraint = rangeConstraint
    }

    init(from constraintToCopy: RecurrenceRuleConstraint, rangeConstraint: ClosedRange<Int>? = nil) throws {
        self.validLowerBound = constraintToCopy.validLowerBound
        self.validUpperBound = constraintToCopy.validUpperBound

        if let range = rangeConstraint {
            let validator = ConstraintValueValidator()
            try validator.validate(value: range.lowerBound, validLowerBound: validLowerBound, validUpperBound: validUpperBound)
            try validator.validate(value: range.upperBound, validLowerBound: validLowerBound, validUpperBound: validUpperBound)
        }
        self.rangeConstraint = rangeConstraint
    }

    func evaluate(_ evaluationAmount: Int) -> EvaluationState {
        if let range = rangeConstraint {
            if range.contains(evaluationAmount) {
                return EvaluationState.passing
            } else {
                return EvaluationState.failed
            }
        } else {
            return EvaluationState.noComparisonAttempted
        }
    }

    func nextValidValue(currentValue: Int) -> Int? {
        var lowestValueGreaterThanCurrentValue: Int?

        if let rangeConstraint = rangeConstraint {
            if (currentValue + 1) <= rangeConstraint.upperBound {
                if let low = lowestValueGreaterThanCurrentValue {
                    if low >= (currentValue + 1) {
                        lowestValueGreaterThanCurrentValue = (currentValue + 1)
                    }
                } else {
                    lowestValueGreaterThanCurrentValue = (currentValue + 1)
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

struct RecurrenceRuleStepConstraint: RecurrenceRuleConstraint {
    let validLowerBound: Int?
    let validUpperBound: Int?
    let stepConstraint: Int?

    var lowestPossibleValue: Int? {
        if stepConstraint != nil {
            return 0
        } else {
            return nil
        }
    }

    var highestPossibleValue: Int? {
        return nil
    }

    var isConstraintActive: Bool {
        if stepConstraint == nil {
            return false
        } else {
            return true
        }
    }

    init(validLowerBound: Int?, validUpperBound: Int?) {
        self.validLowerBound = validLowerBound
        self.validUpperBound = validUpperBound
        self.stepConstraint = nil
    }

    init(from constraintToCopy: RecurrenceRuleConstraint, stepConstraint: Int? = nil) throws {
        self.validLowerBound = constraintToCopy.validLowerBound
        self.validUpperBound = constraintToCopy.validUpperBound

        if let amount = stepConstraint {
            if let validUpperBound = validUpperBound {
                if amount < 1 {
                    throw RecurrenceRuleConstraintError.constraintAmountLessThanLowerBound
                }
                if amount > validUpperBound {
                    throw RecurrenceRuleConstraintError.constraintAmountGreaterThanUpperBound
                }
            }
        }
        self.stepConstraint = stepConstraint
    }

    func evaluate(_ evaluationAmount: Int) -> EvaluationState {
        guard let stepAmount = stepConstraint else {
            return EvaluationState.noComparisonAttempted
        }

        // pass if evaluationAmount is divisiable of stepConstriant
        if evaluationAmount % stepAmount == 0 {
            return EvaluationState.passing
        } else {
            return EvaluationState.failed
        }
    }

    func nextValidValue(currentValue: Int) -> Int? {
        var lowestValueGreaterThanCurrentValue: Int?

        // step
        if let stepValue = stepConstraint {
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
                    multiple = multiple + stepValue
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

                    multiple = multiple + stepValue
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
