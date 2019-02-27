import Foundation

extension Date {
    enum DateManipulationError: Error {
        case couldNotFindNextDate
        case couldNotValidateDateComponentValue
    }

    func setValuesToDefault(LowerThan ruleTimeUnit: RecurrenceRuleTimeUnit, date: Date) -> Date {
        var lowerCadenceLevelUnits = [RecurrenceRuleTimeUnit]()
        switch ruleTimeUnit {
        case .second:
            lowerCadenceLevelUnits = []
        case .minute:
            lowerCadenceLevelUnits = [.second]
        case .hour:
            lowerCadenceLevelUnits = [.second, .minute]
        case .dayOfMonth, .dayOfWeek, .weekOfMonth, .weekOfYear:
            lowerCadenceLevelUnits = [.second, .minute, .hour]
        case .month:
            lowerCadenceLevelUnits = [.second, .minute, .hour, .dayOfMonth]
        case .quarter, .year:
            lowerCadenceLevelUnits = [.second, .minute, .hour, .dayOfMonth, .month]
        }

        var newDate = date
        for unit in lowerCadenceLevelUnits {
            do {
                newDate = try setValueToDefault(unit, date: newDate)
            } catch {
                // do nothing
            }
        }

        return newDate
    }

    func setValueToDefault(_ ruleTimeUnit: RecurrenceRuleTimeUnit, date: Date) throws -> Date {
        guard let defaultValue = resolveValidLowerBound(ruleTimeUnit) else {
            return date
        }
        guard let currentValue = self.resolveDateComponentValue(for: ruleTimeUnit) else {
            throw DateManipulationError.couldNotValidateDateComponentValue
        }

        let dateComponent = resolveCalendarComponent(for: ruleTimeUnit)
        let unitsToSubtract = currentValue - defaultValue

        return Calendar.current.date(byAdding: dateComponent, value: -unitsToSubtract, to: date)!
    }

    func nextDateWhere(next ruleTimeUnit: RecurrenceRuleTimeUnit, is nextValue: Int) throws -> Date? {
        guard let currentValue = self.resolveDateComponentValue(for: ruleTimeUnit) else {
            throw DateManipulationError.couldNotFindNextDate
        }
        let dateComponent = resolveCalendarComponent(for: ruleTimeUnit)
        let dateWithDefaultValues = setValuesToDefault(LowerThan: ruleTimeUnit, date: self)

        let unitsToAdd = try resolveUnitsToAdd(ruleTimeUnit: ruleTimeUnit, currentValue: currentValue, nextValue: nextValue)
        return Calendar.current.date(byAdding: dateComponent, value: unitsToAdd, to: dateWithDefaultValues)
    }

    func resolveUnitsToAdd(ruleTimeUnit: RecurrenceRuleTimeUnit, currentValue: Int, nextValue: Int) throws -> Int {
        if !validate(ruleTimeUnit: ruleTimeUnit, value: currentValue) || !validate(ruleTimeUnit: ruleTimeUnit, value: nextValue) {
            throw DateManipulationError.couldNotValidateDateComponentValue
        }

        var unitsToAdd = nextValue - currentValue
        if unitsToAdd <= 0 {
            if let rangeOfValidBounds = rangeOfValidBounds(ruleTimeUnit) {
                unitsToAdd = unitsToAdd + rangeOfValidBounds
            }
        }

        return unitsToAdd
    }

    func validate(ruleTimeUnit: RecurrenceRuleTimeUnit, value: Int) -> Bool {
        if let validLowerBound = resolveValidLowerBound(ruleTimeUnit) {
            if value < validLowerBound {
                return false
            }
        }

        if let validUpperBound = resolveValidUpperBound(ruleTimeUnit) {
            if value > validUpperBound {
                return false
            }
        }

        return true
    }

    func rangeOfValidBounds(_ ruleTimeUnit: RecurrenceRuleTimeUnit) -> Int? {
        if let validLowerBound = resolveValidLowerBound(ruleTimeUnit), let  validUpperBound = resolveValidUpperBound(ruleTimeUnit) {
            return validUpperBound - validLowerBound
        } else {
            return nil
        }
    }

}
