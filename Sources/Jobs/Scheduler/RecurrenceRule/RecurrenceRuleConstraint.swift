//
//  RecurrenceRuleConstraint.swift
//  Async
//
//  Created by Reid Nantes on 2019-02-22.
//

import Foundation

enum RecurrenceRuleConstraintError: Error {
    case amountToInsertLessThanLowerBound
    case amountToInsertGreaterThanUpperBound
}

final class RecurrenceRuleConstraint {
    private var setConstraint = Set<Int>()
    private var rangeConstraint: ClosedRange<Int>?
    private var stepConstraint: Int? = nil

    private let validLowerBound: Int?
    private let validUpperBound: Int?

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

    // set
    public func addToSet(_ amount: Int) throws {
        try validate(amount)

        setConstraint.insert(amount)
    }

    public func addToSet(_ amounts: [Int]) throws {
        // validate all amounts
        for amount in amounts {
            try validate(amount)
        }

        // insert all amounts
        for amount in amounts {
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

        self.rangeConstraint = lowerBound...upperBound
    }

    // step
    public func setStep(_ amount: Int) throws {
        try validate(amount)

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

}
