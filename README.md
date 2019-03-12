# Jobs
A library that allows for scheduling tasks to be executed at some point in the future. 

# Goals
The goal of this library is twofold: 

1. Allow users to schedule tasks that will be executed at some point in the future.
2. Transparently handle errors, success, and retries. 

In addition, this library should be able to handle various persistence stores. It ships with Redis by default (the implementation can be found at https://github.com/vapor-community/jobs-redis-driver). Eventually, it would be fantastic to get this added to the core Vapor org. 

# Installation
To use the Redis implementation of this package, add this to your `Package.swift`:

```swift
.package(url: "https://github.com/vapor-community/jobs-redis-driver.git", from: "0.1.0")
```

You should not use this package alone unless you plan to reimplement the persistence layer. 

# Usage
There's a full example of this implementation at https://github.com/mcdappdev/jobs-example.

Start by creating a job: 

```swift
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
```

Next, configure the `Jobs` package in your `configure.swift`:

```swift
import Jobs
import JobsRedisDriver

public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Redis
    //MARK: - Redis
    try services.register(RedisProvider())
    
    let redisUrlString = "redis://localhost:6379"
    guard let redisUrl = URL(string: redisUrlString) else { throw Abort(.internalServerError) }
    let redisConfig = try RedisDatabase(config: RedisClientConfig(url: redisUrl))
    
    var databaseConfig = DatabasesConfig()
    databaseConfig.add(database: redisConfig, as: .redis)
    services.register(databaseConfig)
    
    services.register(JobsPersistenceLayer.self) { container -> JobsRedisDriver in
        return JobsRedisDriver(database: redisConfig, eventLoop: container.next())
    }
    
    try jobs(&services)
}

public func jobs(_ services: inout Services, persistenceLayer: JobsPersistenceLayer) throws {
    let jobsProvider = JobsProvider(refreshInterval: .seconds(10))
    try services.register(jobsProvider)
    
    //Register jobs
    services.register { _ -> JobsConfig in
        var jobsConfig = JobsConfig()
        jobsConfig.add(EmailJob.self)
        return jobsConfig
    }
    
    services.register { _ -> CommandConfig in
        var commandConfig = CommandConfig.default()
        commandConfig.use(JobsCommand(), as: "jobs")
        
        return commandConfig
    }
}
```

To add some data to the queue, add a controller like this:

```swift
final class JobsController: RouteCollection {
    let queue: QueueService
    
    init(queue: QueueService) {
        self.queue = queue
    }
    
    func boot(router: Router) throws {
        router.get("/queue", use: addToQueue)
    }
    
    func addToQueue(req: Request) throws -> Future<HTTPStatus> {
        let job = EmailJob(to: "to@to.com", from: "from@from.com", message: "message")
        return queue.dispatch(job: job, maxRetryCount: 10).transform(to: .ok)
    }
}
```

Finally, spin up a queue worker like this:

`vapor build && vapor run jobs`

## Adding a job to a specific queue:
```swift
extension QueueType {
    static let emails = QueueType(name: "emails")
}
```

```swift
func addToQueue(req: Request) throws -> Future<HTTPStatus> {
    let job = EmailJob(to: "to@to.com", from: "from@from.com", message: "message")
    return queue.dispatch(job: job, maxRetryCount: 10, queue = .emails).transform(to: .ok)
}
```

`vapor run jobs --queue emails`

## Handling errors 
There are no public-facing methods that are marked as throwing in this library. To return an error from the dequeue function, for example, do this:

```swift
func dequeue(context: JobContext, worker: EventLoopGroup) -> EventLoopFuture<Void> {   
    return worker.future(error: Abort(.badRequest, reason: "My error here."))
}
```

You can use the `error` method on `Job` to catch any errors thrown in the process and send an email, perform database cleanup, etc. 

# To-Do

- Full documentation in the Vapor docs style
- Potentially ship with a Fluent integration as well
- Look into what it would take to pull this into the main Vapor org
- Tag versions




# RecurrenceRules 
Setting up a `RecurrenceRule` uses similar principles of cron job scheduling

some good references: https://crontab-generator.org/, https://crontab-generator.org/

You can set constraints on these date components (RecurrenceRuleTimeUnits):
* year (1970-)
* quarter (1-4)
* month (1-12) ex: 1 is January, 12 is December
* weekOfYear (1-52)
* weekOfMonth (1-5)
* dayOfMonth (1-31) ex: 1 is the 1st of month, 31 is the 31st of month
* dayOfWeek (1-7) ex: 1 Sunday, 7 Saturday
* hour (0-23)
* minute (0-59)
* second (0-59)

## Setting up RecurrenceRule Constraints

### single values
`RecurrenceRule().atHour(5).atMinute(30).atSecond(19)`
* will run at 5:30:19

### multiple values
`RecurrenceRule().atHours([5, 6]).atMinutes([19, 36])`
* will run at 5:19, 5:36, 6:19, 6:36

### range values
`RecurrenceRule().atHoursInRange(lowerBound: 7, upperBound: 11).atMinute(19)`
* will run at 7:19, 8:19, 9:19, 10:19, 11:19

### step values (.every())
`RecurrenceRule().atHours([5, 6]).every(.minutes(15))`
* will run at 5:00, 5:15, 5:30, 5:45, 6:00, 6:15, 6:30, 6:45, 7:00

*WARNING* step value repeat at the start of higher Date Components
`RecurrenceRule().atHours([5, 6]).every(.minutes(22))`
* will run at 5:00, 5:22, 5:44, 6:00, 6:22, 6:44

### convenience functions
convenience methods also exist, examples include

`RecurrenceRule().every15Minues()`
* equivalent to RecurrenceRule().every(.minutes(22))

`RecurrenceRule().hourly()`
* equivalent to RecurrenceRule().every(.hour(1))

`RecurrenceRule().wednesdays()`
* equivalent to RecurrenceRule().atDayOfWeek(4)

`RecurrenceRule().weekends()`
* equivalent to RecurrenceRule().atDaysOfWeek([1, 7]) 

`RecurrenceRule().monthly()`
* equivalent to RecurrenceRule().atDayOfMonth(1)

### Evaluating Recurrence Rules
You can find if a certain Date satisfies a RecurrenceRule
`evaluate(date: Date) throws -> Bool`

You can find the next Date that will satisfy a RecurrenceRule with 
`resolveNextDateThatSatisfiesRule(date: Date) throws -> Date`
