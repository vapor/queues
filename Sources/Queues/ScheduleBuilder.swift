import Foundation

/// An object that can be used to build a scheduled job
public final class ScheduleBuilder: @unchecked Sendable {
    /// Months of the year
    public enum Month: Int {
        case january = 1
        case february
        case march
        case april
        case may
        case june
        case july
        case august
        case september
        case october
        case november
        case december
    }

    /// Describes a day
    public enum Day: ExpressibleByIntegerLiteral {
        case first
        case last
        case exact(Int)
     
        public init(integerLiteral value: Int) { self = .exact(value) }
    }

    /// Describes a day of the week
    public enum Weekday: Int {
        case sunday = 1
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday
    }

    /// Describes a time of day
    public struct Time: ExpressibleByStringLiteral, CustomStringConvertible {
        /// Returns a `Time` object at midnight (12:00 AM)
        public static var midnight: Time { .init(12, 00, .am) }

        /// Returns a `Time` object at noon (12:00 PM)
        public static var noon: Time { .init(12, 00, .pm) }

        var hour: Hour24, minute: Minute

        init(_ hour: Hour24, _ minute: Minute) { (self.hour, self.minute) = (hour, minute) }
        
        init(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod) {
            self.init(.init(hour.n % 12 + (period == .am ? 0 : 12)), minute)
        }
        
        public init(stringLiteral value: String) {
            let parts = value.split(separator: ":", maxSplits: 1)
        
            guard let hour = Int(parts[0]) else { fatalError("Could not convert hour to Int") }
            switch parts.count {
            case 1:
                self.init(Hour24(hour), 0)
            case 2:
                guard let minute = Int(parts[1].prefix(2)) else { fatalError("Could not convert minute to Int") }
                switch parts[1].count {
                case 2:
                    self.init(Hour24(hour), Minute(minute))
                case 4:
                    self.init(Hour12(hour), Minute(minute), HourPeriod(String(parts[1].dropFirst(2))))
                default:
                    fatalError("Invalid minute format: \(parts[1]), expected 00am/pm")
                }
            default:
                fatalError("Invalid time format: \(value), expected 00:00am/pm")
            }
        }
        
        public var description: String { "\(self.hour):\(self.minute)" }
    }

    /// Represents an hour numeral that must be in 12 hour format
    public struct Hour12: ExpressibleByIntegerLiteral, CustomStringConvertible {
        let n: Int
        
        init(_ n: Int) { precondition((1 ... 12).contains(n), "12-hour clock must be in range 1-12"); self.n = n }
        
        public init(integerLiteral value: Int) { self.init(value) }
        
        public var description: String { "\(self.n)" }
    }

    /// Represents an hour numeral that must be in 24 hour format
    public struct Hour24: ExpressibleByIntegerLiteral, CustomStringConvertible {
        let n: Int
    
        init(_ n: Int) { precondition((0 ..< 24).contains(n), "24-hour clock must be in range 0-23"); self.n = n }
    
        public init(integerLiteral value: Int) { self.init(value) }
    
        public var description: String { String("0\(self.n)".suffix(2)) }
    }

    /// A period of hours - either `am` or `pm`
    public enum HourPeriod: String, ExpressibleByStringLiteral, CustomStringConvertible, Hashable {
        case am, pm
    
        init(_ string: String) { self.init(rawValue: string)! }
    
        public init(stringLiteral value: String) { self.init(value) }
    
        public var description: String { self.rawValue }
    }

    /// Describes a minute numeral
    public struct Minute: ExpressibleByIntegerLiteral, CustomStringConvertible {
        let n: Int
    
        init(_ n: Int) { precondition((0 ..< 60).contains(n), "Minute must be in range 0-59"); self.n = n }
    
        public init(integerLiteral value: Int) { self.init(value) }
    
        public var description: String { String("0\(self.n)".suffix(2)) }
    }
    
    /// Describes a second numeral
    public struct Second: ExpressibleByIntegerLiteral, CustomStringConvertible {
        let n: Int

        init(_ n: Int) { precondition((0 ..< 60).contains(n), "Second must be in range 0-59"); self.n = n }

        public init(integerLiteral value: Int) { self.init(value) }

        public var description: String { String("0\(self.n)".suffix(2)) }
    }

    /// An object to build a `Yearly` scheduled job
    public struct Yearly {
        let builder: ScheduleBuilder

        public func `in`(_ month: Month) -> Monthly { self.builder.month = month; return self.builder.monthly() }
        
        public func `in`(_ month: Month, timezone: TimeZone) -> Monthly {
            self.builder.timezone = timezone
            return self.in(month)
        }
    }

    /// An object to build a `Monthly` scheduled job
    public struct Monthly {
        let builder: ScheduleBuilder

        public func on(_ day: Day) -> Daily { self.builder.day = day; return self.builder.daily() }
        
        public func on(_ day: Day, timezone: TimeZone) -> Daily {
            self.builder.timezone = timezone
            return self.on(day)
        }
    }

    /// An object to build a `Weekly` scheduled job
    public struct Weekly {
        let builder: ScheduleBuilder

        public func on(_ weekday: Weekday) -> Daily { self.builder.weekday = weekday; return self.builder.daily() }
        
        public func on(_ weekday: Weekday, timezone: TimeZone) -> Daily {
            self.builder.timezone = timezone
            return self.on(weekday)
        }
    }

    /// An object to build a `Daily` scheduled job
    public struct Daily {
        let builder: ScheduleBuilder

        public func at(_ time: Time) { self.builder.time = time }

        public func at(_ hour: Hour24, _ minute: Minute) { self.at(.init(hour, minute)) }

        public func at(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod) { self.at(.init(hour, minute, period)) }
        
        public func at(_ time: Time, timezone: TimeZone) {
            self.builder.timezone = timezone
            self.at(time)
        }
        
        public func at(_ hour: Hour24, _ minute: Minute, timezone: TimeZone) {
            self.builder.timezone = timezone
            self.at(hour, minute)
        }
        
        public func at(_ hour: Hour12, _ minute: Minute, _ period: HourPeriod, timezone: TimeZone) {
            self.builder.timezone = timezone
            self.at(hour, minute, period)
        }
    }

    /// An object to build a `Hourly` scheduled job
    public struct Hourly {
        let builder: ScheduleBuilder

        public func at(_ minute: Minute) { self.builder.minute = minute }
        
        public func at(_ minute: Minute, timezone: TimeZone) {
            self.builder.timezone = timezone
            self.at(minute)
        }
    }
    
    /// An object to build a `EveryMinute` scheduled job
    public struct Minutely {
        let builder: ScheduleBuilder

        public func at(_ second: Second) { self.builder.second = second }
        
        public func at(_ second: Second, timezone: TimeZone) {
            self.builder.timezone = timezone
            self.at(second)
        }
    }
    
    /// Retrieves the next date after the one given.
    public func nextDate(current: Date = .init()) -> Date? {
        if let date = self.date, date > current { return date }

        var components = DateComponents()
        components.nanosecond = self.millisecond.map { $0 * 1_000_000 }
        components.second = self.second?.n
        components.minute = self.time?.minute.n ?? self.minute?.n
        components.hour = self.time?.hour.n
        components.weekday = self.weekday?.rawValue
        switch self.day {
        case .first?: components.day = 1
        case .exact(let exact)?: components.day = exact
        case .last?: fatalError("Last day of the month is not yet supported.")
        default: break
        }
        components.month = self.month?.rawValue
        if let timezone = self.timezone {
            self.calendar.timeZone = timezone
        }
        return calendar.nextDate(after: current, matching: components, matchingPolicy: .strict)
    }
    
    /// The calendar used to compute the next date
    var calendar: Calendar
    
    /// The timezone for the schedule
    var timezone: TimeZone?
    
    /// Date to perform task (one-off job)
    var date: Date?
    var month: Month?, day: Day?, weekday: Weekday?
    var time: Time?, minute: Minute?, second: Second?, millisecond: Int?

    public init(calendar: Calendar = .current) { self.calendar = calendar }

    /// Schedules a job using a specific `Calendar`
    public func using(_ calendar: Calendar) -> ScheduleBuilder { self.calendar = calendar; return self }
    
    /// Schedules a job using a specific timezone
    public func `in`(timezone: TimeZone) -> ScheduleBuilder { self.timezone = timezone; return self }

    /// Schedules a job at a specific date
    public func at(_ date: Date) { self.date = date }

    /// Creates a yearly scheduled job for further building
    @discardableResult public func yearly() -> Yearly { .init(builder: self) }

    /// Creates a monthly scheduled job for further building
    @discardableResult public func monthly() -> Monthly { .init(builder: self) }

    /// Creates a weekly scheduled job for further building
    @discardableResult public func weekly() -> Weekly { .init(builder: self) }

    /// Creates a daily scheduled job for further building
    @discardableResult public func daily() -> Daily { .init(builder: self) }

    /// Creates a hourly scheduled job for further building
    @discardableResult public func hourly() -> Hourly { .init(builder: self) }

    /// Creates a minutely scheduled job for further building
    @discardableResult public func minutely() -> Minutely { .init(builder: self) }

    /// Runs a job every second
    public func everySecond() { self.millisecond = 0 }
}
