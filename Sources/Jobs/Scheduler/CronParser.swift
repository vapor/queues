import Foundation

struct CronParser {
    private enum ParseState {
        case lookingForValue
    }

    enum CronParseError: Error {
        case invalidField
        case invalidMinuteField
        case invalidHourField
        case invalidDayOfMonthField
        case invalidMonthField
        case invalidDayOfWeekField
        case tooManyFields
        case missingFields
        case missingMinuteField
        case missingHourField
        case missingDayOfMonthField
        case missingMonthField
        case missingDayOfWeekField
    }

    private static let fieldTimeUnitOrder: [RecurrenceRuleTimeUnit] = [.minute, .hour, .dayOfMonth, .month, .dayOfWeek]

    /// Parses a cron string, to create an ReccurrenceRule
    ///
    /// - Note: single, list, range, and step values accepted using standard cron rules
    /// - Note: allowed values: minute: 0-59, hour: 0-23, day (of month): 1-31, month: 1-12, day (of year): 0-6
    ///
    /// - Parameter cronString: a standard cron string
    /// - Returns: a ReccurrenceRule
    /// - Throws: throws an error if the cron string is invalid
    public static func parse(_ cronString: String) throws -> RecurrenceRule {
        // trim spaces and replace double spaces with single spaces
        var workingString = cronString.trimmingCharacters(in: .whitespacesAndNewlines)
        // replace multiple spaces in row with single space
        workingString = try workingString.replacingOccurrences(ofRegexPattern: "\\s+", with: " ")
        var recurrenceRule = RecurrenceRule()

        if workingString == "* * * * *" {
            recurrenceRule.setMinuteConstraint(try .everyMinute())
            return recurrenceRule
        }

        // split string by space
        let fields = workingString.split(separator: " ")

        for (index, fieldTimeUnit) in fieldTimeUnitOrder.enumerated() {
            if fields.count-1 < index {
                switch fieldTimeUnit {
                case .minute:
                    throw CronParseError.missingMinuteField
                case .hour:
                    throw CronParseError.missingHourField
                case .dayOfMonth:
                    throw CronParseError.missingDayOfMonthField
                case .month:
                    throw CronParseError.missingMonthField
                case .dayOfWeek:
                    throw CronParseError.missingDayOfWeekField
                default:
                    throw CronParseError.missingFields
                }
            }

            let field = fields[index]
            if let constraint = try parseCronField(field: String(field), timeUnit: fieldTimeUnit) {
                switch fieldTimeUnit {
                case .minute:
                    recurrenceRule.setMinuteConstraint(try MinuteRecurrenceRuleConstraint.init(constraint: constraint))
                case .hour:
                    recurrenceRule.setHourConstraint(try HourRecurrenceRuleConstraint.init(constraint: constraint))
                case .dayOfMonth:
                    recurrenceRule.setDayOfMonthConstraint(try DayOfMonthRecurrenceRuleConstraint.init(constraint: constraint))
                case .month:
                    recurrenceRule.setMonthConstraint(try MonthRecurrenceRuleConstraint.init(constraint: constraint))
                case .dayOfWeek:
                    recurrenceRule.setDayOfWeekConstraint(try DayOfWeekRecurrenceRuleConstraint.init(constraint: constraint))
                default:
                    throw CronParseError.invalidField
                }
            }
        }
        if fields.count > fieldTimeUnitOrder.count {
            throw CronParseError.tooManyFields
        }

        return recurrenceRule
    }

    private static func parseCronField(field: String, timeUnit: RecurrenceRuleTimeUnit) throws -> RecurrenceRuleConstraint? {
        // star (any value)
        if field == "*" {
            return nil
        }

        // single value
        if RegexHelper.isCompleteMatch(pattern: "\\d+", inputString: field) {
            return try parseSingleValueField(field: field, timeUnit: timeUnit)
        }

        // range
        if RegexHelper.isCompleteMatch(pattern: "\\d+-\\d+", inputString: field) {
            return try parseRangeField(field: field, timeUnit: timeUnit)
        }

        // step
        if RegexHelper.isCompleteMatch(pattern: "\\*\\/\\d+", inputString: field) {
            return try parseStepField(field: field, timeUnit: timeUnit)
        }

        // list
        if RegexHelper.isCompleteMatch(pattern: "\\d+(?:,\\d+)+", inputString: field) {
            return try parseListField(field: field, timeUnit: timeUnit)
        }

        // should return before this is hit
        throw CronParseError.invalidField
    }

    private static func parseSingleValueField(field: String, timeUnit: RecurrenceRuleTimeUnit) throws -> RecurrenceRuleConstraint {
        guard var value = Int(field) else {
            throw CronParseError.invalidField
        }

        if timeUnit == .dayOfWeek {
            value = value + 1
        }

        return try RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: [value])
    }

    private static func parseListField(field: String, timeUnit: RecurrenceRuleTimeUnit) throws -> RecurrenceRuleSetConstraint {
        // pattern for int array ex 55,2,42,19
        let pattern = "\\d+(?:,\\d+)+"
        guard let match = RegexHelper.firstMatch(for: pattern, inString: field) else {
            throw CronParseError.invalidField
        }
        // check match is the whole field (no trailing commas etc.)
        if match.count != field.count {
            throw CronParseError.invalidField
        }
        var intsInMatch = RegexHelper.allInts(inString: match, shouldIncludeSign: false)

        if timeUnit == .dayOfWeek {
            // subract by 1
            intsInMatch = intsInMatch.map {$0 + 1}
        }

        // array to set
        var intSet = Set<Int>()
        for int in intsInMatch {
            intSet.insert(int)
        }

        return try RecurrenceRuleSetConstraint.init(timeUnit: timeUnit, setConstraint: intSet)
    }

    private static func parseRangeField(field: String, timeUnit: RecurrenceRuleTimeUnit) throws -> RecurrenceRuleConstraint {
        var intsInString = RegexHelper.allInts(inString: field, shouldIncludeSign: false)
        if intsInString.count != 2 {
            throw CronParseError.invalidField
        }
        var lowerBound = intsInString[0]
        var upperBound = intsInString[1]

        if timeUnit == .dayOfWeek {
            lowerBound = lowerBound + 1
            upperBound = upperBound + 1
        }

        return try RecurrenceRuleRangeConstraint.init(timeUnit: timeUnit, rangeConstraint: lowerBound...upperBound)
    }

    private static func parseStepField(field: String, timeUnit: RecurrenceRuleTimeUnit) throws -> RecurrenceRuleConstraint {
        let intsInString = RegexHelper.allInts(inString: field, shouldIncludeSign: false)
        if intsInString.count != 1 {
            throw CronParseError.invalidField
        }

        return try RecurrenceRuleStepConstraint.init(timeUnit: timeUnit, stepConstraint: intsInString[0])
    }
}

private struct RegexHelper {

    static func firstMatchRange(for regexPattern: String, inString inputString: String) -> Range<String.Index>? {
        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: [.caseInsensitive]) else {
            //print("Invalid Regex Pattern: \(regexPattern)")ew
            return nil
        }

        let range = NSRange(inputString.startIndex..., in: inputString)
        let firstMatch = regex.firstMatch(in: inputString, options: [], range: range)

        if let match = firstMatch {
            // first match found
            return Range(match.range, in: inputString)!
        } else {
            // no match found
            return nil
        }
    }

    static func firstMatch(for regexPattern: String, inString inputString: String) -> String? {
        let firstMatchRange = self.firstMatchRange(for: regexPattern, inString: inputString)

        if let range = firstMatchRange {
            // match found
            let matchingString = String(inputString[range])
            return matchingString
        } else {
            // no match found
            return nil
        }
    }

    static func matchRanges(for regexPattern: String, inString inputString: String) -> [Range<String.Index>] {
        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: [.caseInsensitive]) else {
            //print("invalid regex")
            return []
        }

        let range = NSRange(inputString.startIndex..., in: inputString)
        let matches = regex.matches(in: inputString, options: [], range: range)

        var matchRanges = [Range<String.Index>]()
        for match in matches {
            matchRanges.append(Range(match.range, in: inputString)!)
        }

        return matchRanges
    }

    static func matches(for regexPattern: String, inString inputString: String) -> [String] {
        let matchRanges = self.matchRanges(for: regexPattern, inString: inputString)

        var matchingStrings = [String]()
        for range in matchRanges {
            matchingStrings.append(String(inputString[range]))
        }

        return matchingStrings
    }

    func firstMatchRange(for regexPattern: String, inString inputString: String) -> Range<String.Index>? {
        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: [.caseInsensitive]) else {
            //print("Invalid Regex Pattern: \(regexPattern)")
            return nil
        }

        let range = NSRange(inputString.startIndex..., in: inputString)
        let firstMatch = regex.firstMatch(in: inputString, options: [], range: range)

        if let match = firstMatch {
            // first match found
            return Range(match.range, in: inputString)!
        } else {
            // no match found
            return nil
        }
    }

    func replaceFirstMatch(for regexPattern: String, inString inputString: String, withString replacementString: String) -> String {
        let firstMatchRange = self.firstMatchRange(for: regexPattern, inString: inputString)

        if let range = firstMatchRange {
            // match found
            return inputString.replacingCharacters(in: range, with: replacementString)
        } else {
            // no match found
            return inputString
        }
    }

    static func allInts(inString inputString: String, shouldIncludeSign: Bool) -> [Int] {
        // \d+ -> at least one digit
        var pattern = "\\d+"
        if shouldIncludeSign {
            // (-|\+)? -> -, + or nothing
            pattern = "(-|\\+)?\\d+"
        }
        var matchesAsInts = [Int]()
        for matchingString in matches(for: pattern, inString: inputString) {
            matchesAsInts.append(Int(matchingString)!)
        }

        return matchesAsInts
    }

    static func firstInteger(inString inputString: String, shouldIncludeSign: Bool) -> Int? {
        // \d+ -> at least one digit
        var pattern = "\\d+"
        if shouldIncludeSign {
            // (-|\+)? -> -, + or nothing
            pattern = "(-|\\+)?\\d+"
        }
        if let matchingString = firstMatch(for: pattern, inString: inputString) {
            return Int(matchingString)
        } else {
            return nil
        }
    }

    func replaceMatches(for regexPattern: String, inString inputString: String, withString replacementString: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: []) else {
            return inputString
        }

        let range = NSRange(inputString.startIndex..., in: inputString)
        return regex.stringByReplacingMatches(in: inputString, options: [], range: range, withTemplate: replacementString)
    }

    static func isCompleteMatch(pattern: String, inputString: String) -> Bool {
        guard let match = firstMatch(for: pattern, inString: inputString) else {
            return false
        }

        if match.count == inputString.count {
            return true
        } else {
            return false
        }
    }

}

private extension String {
    enum RegexError: Error {
        case invalidPattern
    }

    /// Returns a new string in which all occurrences of regex patten are replaced by another given string
    /// - Returns: A new string
    /// - Throws: A RegexError if pattern is invalid
    func replacingOccurrences(ofRegexPattern pattern: String, with replacementString: String) throws -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            throw RegexError.invalidPattern
        }

        let range = NSRange(self.startIndex..., in: self)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replacementString)
    }
}
