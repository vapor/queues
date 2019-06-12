import Foundation

public final class ScheduleBuilder {
    // MARK: Data Structures

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
    
    public enum Day: ExpressibleByIntegerLiteral {
        case first
        case last
        case exact(Int)
        
        public init(integerLiteral value: Int) {
            self = .exact(value)
        }
    }
    
    public enum DayOfWeek: Int {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
    }
    
    public struct Time: ExpressibleByStringLiteral, CustomStringConvertible {
        public static var midnight: Time {
            return "12:00am"
        }
        public static var noon: Time {
            return "12:00pm"
        }
        
        var hour: Hour24
        var minute: Minute
        
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
                self.hour = .init(hour.number)
            case .pm:
                self.hour = .init(hour.number == 12 ? 0 : hour.number + 12)
            }
            self.minute = minute
        }
        
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
    
    public struct Hour12: ExpressibleByIntegerLiteral, CustomStringConvertible {
        let number: Int
        
        public var description: String {
            return self.number.description
        }
        
        init(_ number: Int) {
            precondition(number > 0, "12-hour clock cannot preceed 1")
            precondition(number <= 12, "12-hour clock cannot exceed 12")
            self.number = number
        }
        
        public init(integerLiteral value: Int) {
            self.init(value)
        }
    }
    
    public struct Hour24: ExpressibleByIntegerLiteral, CustomStringConvertible {
        let number: Int
        
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
        
        public init(integerLiteral value: Int) {
            self.init(value)
        }
    }
    
    public enum HourPeriod: ExpressibleByStringLiteral, CustomStringConvertible {
        case am
        case pm
        
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
        
        public init(stringLiteral value: String) {
            self.init(value)
        }
    }
    
    public struct Minute: ExpressibleByIntegerLiteral, CustomStringConvertible {
        let number: Int
        
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
        
        public init(integerLiteral value: Int) {
            self.init(value)
        }
    }
    
    // MARK: Builders
    
    public struct Yearly {
        let builder: ScheduleBuilder

        public func `in`(_ month: Month) -> Monthly {
            self.builder.month = month
            return self.builder.monthly()
        }
    }

    public struct Monthly {
        let builder: ScheduleBuilder

        public func on(_ day: Day) -> Daily {
            self.builder.day = day
            return self.builder.daily()
        }
    }

    public struct Weekly {
        let builder: ScheduleBuilder
        
        public func on(_ dayOfWeek: DayOfWeek) -> Daily {
            self.builder.dayOfWeek = dayOfWeek
            return self.builder.daily()
        }
    }

    public struct Daily {
        let builder: ScheduleBuilder

        public func at(_ time: Time) {
            self.builder.time = time
        }
    }

    public struct Hourly {
        let builder: ScheduleBuilder
        
        public func at(_ minute: Minute) {
            self.builder.minute = minute
        }
    }
    
    // MARK: Properties
    
    var month: Month?
    var day: Day?
    var dayOfWeek: DayOfWeek?
    var time: Time?
    var minute: Minute?
    
    init() { }
    
    // MARK: Helpers

    public func yearly() -> Yearly {
        return Yearly(builder: self)
    }

    public func monthly() -> Monthly {
        return Monthly(builder: self)
    }
    
    public func weekly() -> Weekly {
        return Weekly(builder: self)
    }

    public func daily() -> Daily {
        return Daily(builder: self)
    }

    public func hourly() -> Hourly {
        return Hourly(builder: self)
    }
}
