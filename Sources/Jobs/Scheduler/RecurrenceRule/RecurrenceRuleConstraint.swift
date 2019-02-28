import Foundation

enum RecurrenceRuleConstraintError: Error {
    case amountToInsertLessThanLowerBound
    case amountToInsertGreaterThanUpperBound
}

final class RecurrenceRuleConstraint {
    private(set) var setConstraint = Set<Int>()
    private(set) var rangeConstraint: ClosedRange<Int>?
    private(set) var stepConstraint: Int?

    private let validLowerBound: Int?
    private let validUpperBound: Int?

    private var lowestPossibleValue: Int?

    init(validLowerBound: Int?, validUpperBound: Int?) {
        self.validLowerBound = validLowerBound
        self.validUpperBound = validUpperBound
    }

    public var isConstraintActive: Bool {
        if setConstraint.isEmpty && rangeConstraint == nil && stepConstraint == nil {
            return false
        }

        return true
    }

    // validate
    private func validate(_ amount: Int) throws {
        if let lowerBound = validLowerBound {
            if amount < lowerBound {
                throw RecurrenceRuleConstraintError.amountToInsertLessThanLowerBound
            }
        }

        if let upperBound = validUpperBound {
            if amount > upperBound {
                throw RecurrenceRuleConstraintError.amountToInsertGreaterThanUpperBound
            }
        }
    }

    private func challengeLowestPossibleValue(_ challenger: Int) {
        if let low = lowestPossibleValue {
            if challenger < low {
                lowestPossibleValue = challenger
            }
        } else {
            lowestPossibleValue = challenger
        }
    }

    // set
    public func addToSet(_ amount: Int) throws {
        try validate(amount)

        challengeLowestPossibleValue(amount)
        setConstraint.insert(amount)
    }

    public func addToSet(_ amounts: [Int]) throws {
        // validate all amounts
        for amount in amounts {
            try validate(amount)
        }

        // insert all amounts
        for amount in amounts {
            challengeLowestPossibleValue(amount)
            setConstraint.insert(amount)
        }
    }

    // range
    internal func createRange(lowerBound: Int, upperBound: Int) throws {
        if lowerBound > upperBound {
            throw RecurrenceRuleError.lowerBoundGreaterThanUpperBound
        }
        try validate(lowerBound)
        try validate(upperBound)

        challengeLowestPossibleValue(lowerBound)
        self.rangeConstraint = lowerBound...upperBound
    }

    // step
    public func setStep(_ amount: Int) throws {
        try validate(amount)

        challengeLowestPossibleValue(0)
        stepConstraint = amount
    }

    public func evaluate(_ evaluationAmount: Int) -> EvaluationState {
        if isConstraintActive == false {
            return EvaluationState.noComparisonAttempted
        }

        let setAndRangeEvaluationState = evaluateSetAndRangeConstraints(evaluationAmount)
        let stepEvaluationState = evaluateStepConstraint(evaluationAmount)

        if setAndRangeEvaluationState == .failed || stepEvaluationState == .failed {
            return EvaluationState.failed
        } else if setAndRangeEvaluationState == .passing || stepEvaluationState == .passing {
            return EvaluationState.passing
        } else {
            return EvaluationState.noComparisonAttempted
        }
    }

    private func evaluateSetAndRangeConstraints(_ evaluationAmount: Int) -> EvaluationState {
        if setConstraint.count > 0 {
            if setConstraint.contains(evaluationAmount) {
                return EvaluationState.passing
            } else {
                return EvaluationState.failed
            }
        }

        if let rangeConstraint = rangeConstraint {
            if rangeConstraint.contains(evaluationAmount) {
                return EvaluationState.passing
            } else {
                return EvaluationState.failed
            }
        }

        return EvaluationState.noComparisonAttempted
    }

    private func evaluateStepConstraint(_ evaluationAmount: Int) -> EvaluationState {
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

    public func nextValidValue(currentValue: Int) -> Int? {
        var lowestValueGreaterThanCurrentValue: Int?

        if setConstraint.count > 0 {
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
        }

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
