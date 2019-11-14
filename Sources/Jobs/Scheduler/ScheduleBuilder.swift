import Foundation

/// An object that can be used to build a scheduled job
public final class ScheduleBuilder {
    // MARK: Data Structures
    /// Months of the year
    public enum Month: Int {
        case january = 1
        case february = 2
        case march = 3
        case april = 4
        case may = 5
        case june = 6
        case july = 7
        case august = 8
        case september = 9
        case october = 10
        case november = 11
        case december = 12
    }

    /// Describes a day
    public enum Day: ExpressibleByIntegerLiteral {
        case first
        case last
        case exact(Int)

        public init(integerLiteral value: Int) {
            self = .exact(value)
        }
    }

    /// Describes a day of the week
    public enum DayOfWeek: Int {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
    }

    /// Describes a time of day
    public struct Time: ExpressibleByStringLiteral, CustomStringConvertible {
        var hour: Hour24
        var minute: Minute

        /// Returns a `Time` object at midnight (12:00 AM)
        public static var midnight: Time {
            return .init(12, 00, .am)
        }

        /// Returns a `Time` object at noon (12:00 PM)
        public static var noon: Time {
            return .init(12, 00, .pm)
        }

        /// The readable description of the time
        public var description: String {
            return "\(self.hour):\(self.minute)"
        }

        init(_ hour: Hour24, _ minute: Minute) {
            self.hour = hour
            self.minute = minute
        }

        init(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod) {
            switch period {
                case .am:
                    if hour.number == 12 && minute.number == 0 {
                        self.hour = .init(0)
                    } else {
                        self.hour = .init(hour.number)
                }
                case .pm:
                    if hour.number == 12 {
                        self.hour = .init(12)
                    } else {
                        self.hour = .init(hour.number + 12)
                }
            }
            self.minute = minute
        }

        /// Takes a stringLiteral and returns a `TimeObject`. Must be in the format `00:00am/pm`
        public init(stringLiteral value: String) {
            let parts = value.split(separator: ":")
            switch parts.count {
                case 1:
                    guard let hour = Int(parts[0]) else {
                        fatalError("Could not convert hour to Int")
                    }
                    self.init(Hour24(hour), 0)
                case 2:
                    guard let hour = Int(parts[0]) else {
                        fatalError("Could not convert hour to Int")
                    }
                    switch parts[1].count {
                        case 2:
                            guard let minute = Int(parts[1]) else {
                                fatalError("Could not convert minute to Int")
                            }
                            self.init(Hour24(hour), Minute(minute))
                        case 4:
                            let s = parts[1]
                            guard let minute = Int(s[s.startIndex..<s.index(s.startIndex, offsetBy: 2)]) else {
                                fatalError("Could not convert minute to Int")
                            }
                            let period = String(s[s.index(s.startIndex, offsetBy: 2)..<s.endIndex])
                            self.init(Hour12(hour), Minute(minute), HourPeriod(period))
                        default:
                            fatalError("Invalid minute format: \(parts[1]), expected 00am/pm")
                }
                default:
                    fatalError("Invalid time format: \(value), expected 00:00am/pm")
            }
        }
    }

    /// Represents an hour numeral that must be in 12 hour format
    public struct Hour12: ExpressibleByIntegerLiteral, CustomStringConvertible {
        let number: Int

        /// The readable description of the hour
        public var description: String {
            return self.number.description
        }

        init(_ number: Int) {
            precondition(number > 0, "12-hour clock cannot preceed 1")
            precondition(number <= 12, "12-hour clock cannot exceed 12")
            self.number = number
        }

        /// Takes an integerLiteral and creates a `Hour12`. Must be `> 0 && <= 12`
        public init(integerLiteral value: Int) {
            self.init(value)
        }
    }

    /// Represents an hour numeral that must be in 24 hour format
    public struct Hour24: ExpressibleByIntegerLiteral, CustomStringConvertible {
        let number: Int

        /// The readable description of the hour, zero padding included
        public var description: String {
            switch self.number {
                case 0..<10:
                    return "0" + self.number.description
                default:
                    return self.number.description
            }
        }

        init(_ number: Int) {
            precondition(number >= 0, "24-hour clock cannot preceed 0")
            precondition(number < 24, "24-hour clock cannot exceed 24")
            self.number = number
        }

        /// Takes an integerLiteral and creates a `Hour24`. Must be `>= 0 && < 24`
        public init(integerLiteral value: Int) {
            self.init(value)
        }
    }

    /// A period of hours - either `am` or `pm`
    public enum HourPeriod: ExpressibleByStringLiteral, CustomStringConvertible {
        case am
        case pm

        /// The readable string
        public var description: String {
            switch self {
                case .am:
                    return "am"
                case .pm:
                    return "pm"
            }
        }

        init(_ string: String) {
            switch string.lowercased() {
                case "am":
                    self = .am
                case "pm":
                    self = .pm
                default:
                    fatalError("Unknown hour period: \(string), must be am or pm")
            }
        }

        /// Takes a stringLiteral and creates a `HourPeriod.` Must be `am` or `pm`
        public init(stringLiteral value: String) {
            self.init(value)
        }
    }

    /// Describes a minute numeral
    public struct Minute: ExpressibleByIntegerLiteral, CustomStringConvertible {
        let number: Int

        /// The readable minute, zero padded.
        public var description: String {
            switch self.number {
                case 0..<10:
                    return "0" + self.number.description
                default:
                    return self.number.description
            }
        }

        init(_ number: Int) {
            assert(number >= 0, "Minute cannot preceed 0")
            assert(number < 60, "Minute cannot exceed 60")
            self.number = number
        }

        /// Takes an integerLiteral and creates a `Minute`. Must be `>= 0 && < 60`
        public init(integerLiteral value: Int) {
            self.init(value)
        }
    }

    /// Describes a second numeral
    public struct Second: ExpressibleByIntegerLiteral, CustomStringConvertible {
        let number: Int

        /// The readable second, zero padded.
        public var description: String {
            switch self.number {
                case 0..<10:
                    return "0" + self.number.description
                default:
                    return self.number.description
            }
        }

        init(_ number: Int) {
            assert(number >= 0, "Second cannot preceed 0")
            assert(number < 60, "Second cannot exceed 60")
            self.number = number
        }

        /// Takes an integerLiteral and creates a `Second`. Must be `>= 0 && < 60`
        public init(integerLiteral value: Int) {
            self.init(value)
        }
    }

    // MARK: Builders
    /// An object to build a `Yearly` scheduled job
    public struct Yearly {
        let builder: ScheduleBuilder

        /// The month to run the job in
        /// - Parameter month: A `Month` to run the job in
        public func `in`(_ month: Month) -> Monthly {
            self.builder.month = month
            return self.builder.monthly()
        }
    }

    /// An object to build a `Monthly` scheduled job
    public struct Monthly {
        let builder: ScheduleBuilder

        /// The day to run the job on
        /// - Parameter day: A `Day` to run the job on
        public func on(_ day: Day) -> Daily {
            self.builder.day = day
            return self.builder.daily()
        }
    }

    /// An object to build a `Weekly` scheduled job
    public struct Weekly {
        let builder: ScheduleBuilder

        /// The day of week to run the job on
        /// - Parameter dayOfWeek: A `DayOfWeek` to run the job on
        public func on(_ dayOfWeek: DayOfWeek) -> Daily {
            self.builder.dayOfWeek = dayOfWeek
            return self.builder.daily()
        }
    }

    /// An object to build a `Daily` scheduled job
    public struct Daily {
        let builder: ScheduleBuilder

        /// The time to run the job at
        /// - Parameter time: A `Time` object to run the job on
        public func at(_ time: Time) {
            self.builder.time = time
        }

        /// The 24 hour time to run the job at
        /// - Parameter hour: A `Hour24` to run the job at
        /// - Parameter minute: A `Minute` to run the job at
        public func at(_ hour: Hour24, _ minute: Minute) {
            self.at(.init(hour, minute))
        }

        /// The 12 hour time to run the job at
        /// - Parameter hour: A `Hour12` to run the job at
        /// - Parameter minute: A `Minute` to run the job at
        /// - Parameter period: A `HourPeriod` to run the job at (`am` or `pm`)
        public func at(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod) {
            self.at(.init(hour, minute, period))
        }
    }

    /// An object to build a `Hourly` scheduled job
    public struct Hourly {
        let builder: ScheduleBuilder

        /// The minute to run the job at
        /// - Parameter minute: A `Minute` to run the job at
        public func at(_ minute: Minute) {
            self.builder.minute = minute
        }
    }

    /// An object to build a `EveryMinute` scheduled job
    public struct EveryMinute {
        let builder: ScheduleBuilder

        /// The second to run the job at
        /// - Parameter second: A `Second` to run the job at
        public func at(_ second: Second) {
            self.builder.second = second
        }
    }

    /// returns the next date that satisfies the schedule
    internal func resolveNextDateThatSatisifiesSchedule(date: Date) throws -> Date {
        if let oneTimeDate = self.date {
            return oneTimeDate
        }

        var monthConstraint: MonthRecurrenceRuleConstraint?
        if let monthValue = month?.rawValue {
            monthConstraint = try MonthRecurrenceRuleConstraint.atMonth(monthValue)
        }

        var dayOfMonthConstraint: DayOfMonthRecurrenceRuleConstraint?
        if let dayValue = day {
            switch dayValue {
                case .first:
                    dayOfMonthConstraint = try DayOfMonthRecurrenceRuleConstraint.atDayOfMonth(1)
                case .last:
                    dayOfMonthConstraint = try DayOfMonthRecurrenceRuleConstraint.atLastDayOfMonth()
                case .exact(let exactValue):
                    dayOfMonthConstraint = try DayOfMonthRecurrenceRuleConstraint.atDayOfMonth(exactValue)
            }
        }

        var dayOfWeekConstraint: DayOfWeekRecurrenceRuleConstraint?
        if let dayOfWeek = dayOfWeek {
            dayOfWeekConstraint = try DayOfWeekRecurrenceRuleConstraint.atDayOfWeek(dayOfWeek.rawValue)
        }

        var hourConstraint: HourRecurrenceRuleConstraint?
        if let hourValue = time?.hour.number {
            hourConstraint = try HourRecurrenceRuleConstraint.atHour(hourValue)
        }

        var minuteConstraint: MinuteRecurrenceRuleConstraint?
        if let timeMinuteValue = time?.minute.number {
            minuteConstraint = try MinuteRecurrenceRuleConstraint.atMinute(timeMinuteValue)
        }

        if let minuteValue = minute?.number {
            minuteConstraint = try MinuteRecurrenceRuleConstraint.atMinute(minuteValue)
        }

        let secondConstraint = try SecondRecurrenceRuleConstraint.atSecond(second.number)
        let recurrenceRule = try RecurrenceRule(yearConstraint: nil,
                                                monthConstraint: monthConstraint,
                                                dayOfMonthConstraint: dayOfMonthConstraint,
                                                dayOfWeekConstraint: dayOfWeekConstraint,
                                                hourConstraint: hourConstraint,
                                                minuteConstraint: minuteConstraint,
                                                secondConstraint: secondConstraint)

        return try recurrenceRule.resolveNextDateThatSatisfiesRule(currentDate: date)
    }

    // MARK: Properties

    /// Date to perform task (one-off job)
    var date: Date?

    var month: Month?
    var day: Day?
    var dayOfWeek: DayOfWeek?
    var time: Time?
    var minute: Minute?
    var second: Second = Second(0)

    init() { }

    // MARK: Helpers

    /// Schedules a job at a specific date
    public func at(_ date: Date) -> Void {
        self.date = date
    }

    /// Creates a yearly scheduled job for further building
    public func yearly() -> Yearly {
        return Yearly(builder: self)
    }

    /// Creates a monthly scheduled job for further building
    public func monthly() -> Monthly {
        return Monthly(builder: self)
    }

    /// Creates a weekly scheduled job for further building
    public func weekly() -> Weekly {
        return Weekly(builder: self)
    }

    /// Creates a daily scheduled job for further building
    public func daily() -> Daily {
        return Daily(builder: self)
    }

    /// Creates a hourly scheduled job for further building
    public func hourly() -> Hourly {
        return Hourly(builder: self)
    }

    public func everyMinute() -> EveryMinute {
        return EveryMinute(builder: self)
    }
}
