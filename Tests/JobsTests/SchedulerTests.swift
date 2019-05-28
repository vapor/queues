import XCTest
import NIO
@testable import Jobs

final class SchedulerTests: XCTestCase {

    func testCustomConstriants() throws {
        let yearConstraint = try YearRecurrenceRuleConstraint.atYear(2043)
        let dayOfWeekConstraint = try DayOfWeekRecurrenceRuleConstraint.atDaysOfWeek([1, 4, 6])
        let hourConstraint = try HourRecurrenceRuleConstraint.atHoursInRange(lowerBound: 3, upperBound: 8)
        let secondConstraint = try SecondRecurrenceRuleConstraint.secondStep(11)

        //let emailJob = EmailJob(to: "to@to.com", from: "from@from.com", message: "message")
        Scheduler().whenConstraintsSatisfied(yearConstraint: yearConstraint,
                                                    dayOfWeekConstraint: dayOfWeekConstraint,
                                                    hourConstraint: hourConstraint,
                                                    secondConstraint: secondConstraint)
    }

    struct EmailJob: Job {
        let to: String
        let from: String
        let message: String

        func dequeue(context: JobContext, worker: EventLoopGroup) -> EventLoopFuture<Void> {
            print(to)
            print(from)
            print(message)

            return worker.future()
        }

        func error(context: JobContext, error: Error, worker: EventLoopGroup) -> EventLoopFuture<Void> {
            print(error)
            return worker.future()
        }
    }

    func testScheduler() throws {
        let schedule = try Scheduler().weekly(on: .saturday).at(.midnight)

        let emailJob = EmailJob(to: "to@to.com", from: "from@from.com", message: "message")
        jobs.schedule(emailJob)


        try Scheduler().fridays().atHour(4).atMinute(2).atSecond(30)
        try Scheduler().yearly().on(.december, 25).at(.midnight)
        try Scheduler().monthly().atDayOfMonth(4).atHour(4).atMinute(4).atSecond(4)
        try Scheduler().weekly(onDayOfWeek: 4).atHour(3).atMinute(2).atSecond(2)
        try Scheduler().weekdays().atHour(4).atMinute(3).atSecond(2)
        try Scheduler().wednesdays().atHour(3).atMinute(1).atSecond(4)
        try Scheduler().daily().atHour(2).atMinute(2).atSecond(1)
        try Scheduler().hourly().atMinute(2).atSecond(4)
        try Scheduler().everyThirtyMinutes().atSecond(5)
        try Scheduler().everyMinute().atSecond(4)
        try Scheduler().yearly().atMonth(5).atDayOfMonth(30).at("11:20").atSecond(30)
        try Scheduler().weekly(on:.saturday).at(.midnight)
        try Scheduler().fridays().atHour(4).atMinute(3).atSecond(0)


        try Scheduler().sundays().atHour(5)

        try Scheduler().weekdays().at(.noon)


        try Scheduler().yearly().on(.december, 24).at(.noon)
        try Scheduler().daily().atHour(2).atMinute(2).atSecond(1)

        try Scheduler().yearly().on(.april, 20).at(.noon)
        try Scheduler().fridays().at("14:32").atSecond(0)

//        let emailJob = EmailJob(to: "to@to.com", from: "from@from.com", message: "message")
//        schedule(emailJob).yearly().on(.december, 24).at(.midnight)
    }

    static var allTests = [
        ("testCustomConstriants", testCustomConstriants),
        ("testScheduler", testScheduler)
    ]
}
