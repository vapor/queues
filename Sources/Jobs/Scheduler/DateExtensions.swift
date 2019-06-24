import Foundation

internal extension Calendar {
    enum CalendarExtensionError: Error {
        case counldNotFindLowerBoundForRecurrenceRuleTimeUnit
        case counldNotFindUpperBoundForRecurrenceRuleTimeUnit
    }

    /// validates a value is within the bounds
    ///
    /// - Parameters:
    ///   - ruleTimeUnit: The TimeUnit to check value against
    ///   - value: the value to check
    /// - Returns:  true if value is valid, false if value is invalid
    func validate(ruleTimeUnit: RecurrenceRule.TimeUnit, value: Int) throws -> Bool {
        if let validLowerBound = try self.lowerBound(for: ruleTimeUnit) {
            if value < validLowerBound {
                return false
            }
        }

        if let validUpperBound = try Calendar.current.upperBound(for: ruleTimeUnit) {
            if value > validUpperBound {
                return false
            }
        }

        return true
    }

    /// Finds the range amount (validUpperBound - validLowerBound) given a RecurrenceRule.TimeUnit
    ///
    /// - Parameter ruleTimeUnit: The RecurrenceRule.TimeUnit to reference
    /// - Returns: The range (validUpperBound - validLowerBound)
    /// - Throws: will throw if no lowerBound or upperBound is available for a given RecurrenceRule.TimeUnit
    func rangeOfValidBounds(_ ruleTimeUnit: RecurrenceRule.TimeUnit) throws -> Int? {
        guard let validLowerBound = try lowerBound(for: ruleTimeUnit) else {
            return nil
        }

        guard let validUpperBound = try upperBound(for: ruleTimeUnit) else {
            return nil
        }

        return validUpperBound - validLowerBound
    }

    ///  Resolves The lower bound (inclusive) of a given RecurrenceRule.TimeUnit
    ///
    /// - Parameter ruleTimeUnit: The referenced RecurrenceRule.TimeUnit
    /// - Returns: The lower bound(inclusive)
    func lowerBound(for ruleTimeUnit: RecurrenceRule.TimeUnit) throws -> Int? {
        switch self.identifier {
        case .gregorian, .iso8601:
            return Calendar.gregorianLowerBound(for: ruleTimeUnit)
        default:
            throw CalendarExtensionError.counldNotFindLowerBoundForRecurrenceRuleTimeUnit
        }
    }

    ///  Resolves The upper bound (inclusive) of a given RecurrenceRule.TimeUnit
    ///
    /// - Parameter ruleTimeUnit: The referenced RecurrenceRule.TimeUnit
    /// - Returns: The upper bound(inclusive)
    func upperBound(for ruleTimeUnit: RecurrenceRule.TimeUnit) throws -> Int? {
        switch self.identifier {
        case .gregorian, .iso8601:
            return Calendar.gregorianUpperBound(for: ruleTimeUnit)
        default:
            throw CalendarExtensionError.counldNotFindUpperBoundForRecurrenceRuleTimeUnit
        }
    }

    static func gregorianLowerBound(for ruleTimeUnit: RecurrenceRule.TimeUnit) -> Int? {
        switch ruleTimeUnit {
        case .second:
            return 0
        case .minute:
            return 0
        case .hour:
            return 0
        case .dayOfWeek:
            return 1
        case .dayOfMonth:
            return 1
        case .month:
            return 1
        case .quarter:
            return 1
        case .year:
            return 1970
        }
    }

    static func gregorianUpperBound(for ruleTimeUnit: RecurrenceRule.TimeUnit) -> Int? {
        switch ruleTimeUnit {
        case .second:
            return 59
        case .minute:
            return 59
        case .hour:
            return 23
        case .dayOfWeek:
            return 7
        case .dayOfMonth:
            return 31
        case .month:
            return 12
        case .quarter:
            return 4
        case .year:
            return nil
        }
    }

}
