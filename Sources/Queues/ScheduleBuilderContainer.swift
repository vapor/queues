import struct Foundation.DateComponents
import struct Foundation.Calendar
import struct Foundation.UUID

/// An object that can be used to build a scheduled job
public final class ScheduleBuilderContainer {
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
    public enum Weekday: Int {
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
    
    public final class Builder {
        
        /// An object to build a `Yearly` scheduled job
        public struct Yearly {
            let builder: Builder

            /// The month to run the job in
            /// - Parameter month: A `Month` to run the job in
            public func `in`(_ month: Month) -> Monthly {
                self.builder.month = month
                return self.builder.monthly()
            }
        }

        /// An object to build a `Monthly` scheduled job
        public struct Monthly {
            let builder: Builder

            /// The day to run the job on
            /// - Parameter day: A `Day` to run the job on
            public func on(_ day: Day) -> Daily {
                self.builder.day = day
                return self.builder.daily()
            }
        }

        /// An object to build a `Weekly` scheduled job
        public struct Weekly {
            let builder: Builder
            
            /// The day of week to run the job on
            /// - Parameter dayOfWeek: A `DayOfWeek` to run the job on
            public func on(_ weekday: Weekday) -> Daily {
                self.builder.weekday = weekday
                return self.builder.daily()
            }
        }

        /// An object to build a `Daily` scheduled job
        public struct Daily {
            let builder: Builder
            
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
            let builder: Builder
            
            /// Runs the job multiple times
            /// - Parameter amount: A period after which the job will be repeated as
            /// many times as an hour allows.
            public func every(_ amount: TimeAmount) {
                self.builder.every(amount, in: .hours(1))
            }
            
            /// The minute to run the job at
            /// - Parameter minute: A `Minute` to run the job at
            public func at(_ minute: Minute) {
                self.builder.minute = minute
            }
        }
        
        /// An object to build a `EveryMinute` scheduled job
        public struct Minutely {
            let builder: Builder
            
            /// Runs the job multiple times
            /// - Parameter amount: A period after which the job will be repeated as
            /// many times as a minute allows.
            public func every(_ amount: TimeAmount) {
                self.builder.every(amount, in: .minutes(1))
            }
            
            /// The second to run the job at
            /// - Parameter second: A `Second` to run the job at
            public func at(_ second: Second) {
                self.builder.second = second
            }
        }
        
        public var container: ScheduleBuilderContainer
        let id = UUID()
        /// Date to perform task (one-off job)
        var date: Date?
        var month: Month?
        var day: Day?
        var weekday: Weekday?
        var time: Time?
        var minute: Minute?
        var second: Second?
        var nanosecond: Int?
        
        public init(container: ScheduleBuilderContainer) {
            self.container = container
            let isBuilderInContainer = container.builders.contains(where: { $0.id == self.id })
            if !isBuilderInContainer {
                container.builders.append(self)
            }
        }
        
        // MARK: Helpers
        
        /// Populates `Builder`s date times using a `TimeAmount`
        /// - Parameter amount: A `TimeAmount` less than a week.
        private func _populateDates(using amount: TimeAmount) {
            let timeAmount = Int(amount.nanoseconds)
            let nanoFactor = 1000_000_000
            self.nanosecond = timeAmount % nanoFactor
            var timeSeconds = timeAmount / nanoFactor
            
            func populateUpToADay() {
                let hours = timeSeconds / 3600
                timeSeconds -= hours * 3600
                let minutes = timeSeconds / 60
                timeSeconds -= minutes * 60
                let seconds = timeSeconds
                if hours != 0 {
                    self.time = .init(.init(hours), .init(minutes))
                } else {
                    self.minute = .init(minutes)
                }
                self.second = .init(seconds)
            }
            
            let dayInSeconds = 24 * 60 * 60
            if timeSeconds < dayInSeconds {
                populateUpToADay()
            } else if timeSeconds < dayInSeconds {
                let days = timeSeconds / dayInSeconds
                timeSeconds -= days * dayInSeconds
                let currentWeekday = Calendar.current.component(.weekday, from: Date())
                /// Next weekday total number
                let weekdayTotalNumber = currentWeekday + days + 1
                /// Reduced weekday number to the acceptable range 1...7
                let weekdayNumber = ((weekdayTotalNumber - 1) % 7) + 1
                let weekday = Weekday(rawValue: weekdayNumber)
                self.weekday = weekday
                populateUpToADay()
            } else {
                fatalError("Time amount \(timeAmount) is more than a week.")
            }
        }
        
        /// Runs a job every `amount` in the `interval`
        ///
        /// `underestimatedCount` Explanation:
        /// underestimatedCount is only useful in some cases when
        /// interval.nanoseconds % amount.nanoseconds is non-zero.
        /// It will decide whether the function should use the most possible
        /// number of jobs possible using the provided `amount` and `interval`
        /// or it should use the lower count of jobs.
        ///
        /// By example, imagine `amount` is equal to _5 hours_ and `interval` is
        /// equal to _22 hours_.
        ///
        /// when `underestimatedCount` is `true`, the number of jobs created
        /// will be [22 / 5] = 4, which will be done on hours 0, 5, 10 and 15.
        /// In this case, it will __not__ schedule a job for the hour _20_ because
        /// the period between the hour _20_ and the next hour _0_ is only 3 hours
        /// and preceeds the value of `amount` which is _5_ hours.
        /// But, when `underestimatedCount` is set to `false`, the function
        /// __will__ include the hour _20_ although the interval between
        /// the hour _20_ and the next _0_ hour is only _3_ and preceeds
        /// the `amount` _5_.
        ///
        /// - Parameter amount: A `TimeAmount` less than a week.
        /// - Parameter interval: A `TimeAmount` less than a week.
        /// use `.monthly()`, `.yearly()` or `.at(_:)` for amounts more than a week.
        /// - Parameter underestimatedCount: Decides whether the function should underestimate
        /// count of jobs or overestimate.
        public func every(
            _ amount: TimeAmount,
            in interval: TimeAmount,
            underestimatedCount: Bool = false
        ) {
            let nanoInterval = Int(interval.nanoseconds)
            let nanoAmount = Int(amount.nanoseconds)
            guard nanoAmount > 0, nanoAmount <= nanoInterval else {
                fatalError("Amount \(amount.nanoseconds) is greater than interval \(interval.nanoseconds), or is not positive.")
            }
            let runCount: Int
            if underestimatedCount {
                runCount = nanoInterval / nanoAmount
            } else {
                runCount = Int((Double(nanoInterval) / Double(nanoAmount)).rounded(.up))
            }
            let timeAmounts = (0..<runCount).map { index in
                index * nanoAmount
            }
            /// After using `.every` on top a `Builder`, the current builder
            /// is populated with the first schedule's time, and the next schedule times
            /// will have a new builder created for them and added to the container.
            timeAmounts.enumerated().forEach { index, timeAmount in
                let builder: Builder
                switch index {
                case 0: builder = self
                default: builder = Builder(container: self.container)
                }
                builder._populateDates(using: .nanoseconds(Int64(timeAmount)))
            }
        }
        
        /// Schedules a job at the specified dates
        public func at(_ dates: Date...) -> Void {
            self.at(dates)
        }
        
        /// Schedules a job at the specified dates
        public func at(_ dates: [Date]) -> Void {
            dates.enumerated().forEach { index, date in
                if index == 0 {
                    self.date = date
                } else {
                    self.container.makeBuilder().date = date
                }
            }
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
        
        /// Creates a minutely scheduled job for further building
        @discardableResult
        public func minutely() -> Minutely {
            return Minutely(builder: self)
        }
        
        /// Runs a job every second
        public func everySecond() {
            self.every(.seconds(1), in: .seconds(1))
        }
        
        /// Retrieves the next date
        /// - Parameter current: The current date
        /// - Returns: The next date
        public func nextDate(current: Date = .init()) -> Date? {
            if let date = self.date, date > current {
                return date
            }
            
            var components = DateComponents()
            if let nanoseconds = nanosecond {
                components.nanosecond = nanoseconds
            }
            if let second = self.second {
                components.second = second.number
            }
            if let minute = self.minute {
                components.minute = minute.number
            }
            if let time = self.time {
                components.minute = time.minute.number
                components.hour = time.hour.number
            }
            if let weekday = self.weekday {
                components.weekday = weekday.rawValue
            }
            if let day = self.day {
                switch day {
                case .first:
                    components.day = 1
                case .last:
                    fatalError("Last day of the month is not yet supported.")
                case .exact(let exact):
                    components.day = exact
                }
            }
            if let month = self.month {
                components.month = month.rawValue
            }
            return Calendar.current.nextDate(
                after: current,
                matching: components,
                matchingPolicy: .strict
            )
        }
        
    }
    
    public var builders: [Builder] = []
    
    public init() { }
    
    // MARK: Helpers
    
    private func makeBuilder() -> Builder {
        let builder = Builder.init(container: self)
        return builder
    }
    
    /// Schedules a job at a specific date
    public func at(_ date: Date) -> Void {
        self.makeBuilder().date = date
    }
    
    /// Creates a yearly scheduled job for further building
    public func yearly() -> Builder.Yearly {
        return Builder.Yearly(builder: self.makeBuilder())
    }

    /// Creates a monthly scheduled job for further building
    public func monthly() -> Builder.Monthly {
        return Builder.Monthly(builder: self.makeBuilder())
    }

    /// Creates a weekly scheduled job for further building
    public func weekly() -> Builder.Weekly {
        return Builder.Weekly(builder: self.makeBuilder())
    }

    /// Creates a daily scheduled job for further building
    public func daily() -> Builder.Daily {
        return Builder.Daily(builder: self.makeBuilder())
    }

    /// Creates a hourly scheduled job for further building
    public func hourly() -> Builder.Hourly {
        return Builder.Hourly(builder: self.makeBuilder())
    }
    
    /// Creates a minutely scheduled job for further building
    @discardableResult
    public func minutely() -> Builder.Minutely {
        return Builder.Minutely(builder: self.makeBuilder())
    }
    
    /// Runs a job every second
    public func everySecond() {
        self.makeBuilder().everySecond()
    }
    
    /// Runs a job every `amount` in the `interval`
    ///
    /// Notes:
    /// * day length is estimated as 24 hours.
    /// * week length is estimated as 24 * 7 hours.
    ///
    /// - Parameter amount: A `TimeAmount` less than a week.
    /// - Parameter interval: A `TimeAmount` less than a week.
    /// use `.monthly()`, `.yearly()` or `.at(_:)` for amounts more than a week.
    /// - Parameter underestimatedCount: Decides whether the function should underestimate
    /// count of the created jobs or overestimate.
    public func every(
        _ amount: TimeAmount,
        in interval: TimeAmount,
        underestimatedCount: Bool = false
    ) {
        self.makeBuilder().every(
            amount,
            in: interval,
            underestimatedCount: underestimatedCount
        )
    }
    
}


