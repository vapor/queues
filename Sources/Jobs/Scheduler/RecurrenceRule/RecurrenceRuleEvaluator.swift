//
//  RecurrenceRuleEvaluator.swift
//  App
//
//  Created by Reid Nantes on 2019-01-28.
//

import Foundation

func RecurrenceRuleEvaluator() {

    func evaluate(currentDate: Date, recurrenceRule: RecurrenceRule) throws -> Bool {
        var ruleEvaluationState = EvaluationState.noComparisonAttempted

        ruleEvaluationState = try evaluateStatelessSchedulingConstraints(currentDate: currentDate, recurrenceRule: recurrenceRule)

        if ruleEvaluationState == .passing {
            return true
        } else {
            return false
        }
    }

    func evaluateStatelessSchedulingConstraints(currentDate: Date, recurrenceRule: RecurrenceRule) throws -> EvaluationState{
        var ruleEvaluationState = EvaluationState.noComparisonAttempted

        try RecurrenceRuleTimeUnit.allCases.forEach {
            var componentEvaluationState = try recurrenceRule.doesSatisfyRule($0, currentDate: currentDate)

            if componentEvaluationState == .failed {
                ruleEvaluationState = EvaluationState.failed
                return
            } else if componentEvaluationState == .passing {
                componentEvaluationState = .passing
            }
        }

        return ruleEvaluationState
    }

    // to do
    func evalutateStepSchedulingConstraints() {

    }
}
