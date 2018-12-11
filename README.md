# Jobs
A library that allows for scheduling tasks to be executed at some point in the future. 

# Goals
The goal of this library is twofold: 

1. Allow users to schedule tasks that will be executed at some point in the future.
2. Transparently handle errors, success, and retries. 

In addition, this library should be able to handle various persistence stores. It ships with Redis by default (the implementation can be found at https://github.com/vapor-community/redis-jobs). Eventually, it would be fantastic to get this added to the core Vapor org. 

# Installation
To use the Redis implementation of this package, add this to your `Package.swift`:

```swift
.package(url: "https://github.com/vapor-community/redis-jobs.git", .branch("master"))
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
    
    try jobs(&services, persistenceLayer: redisConfig)
}

public func jobs(_ services: inout Services, persistenceLayer: JobsPersistenceLayer) throws {
    /// Jobs
    let jobsProvider = JobsProvider(persistenceLayer: persistenceLayer, refreshInterval: .seconds(1))
    try services.register(jobsProvider)
    
    //Register jobs
    var jobsConfig = JobsConfig()
    jobsConfig.add(EmailJob.self)
    services.register(jobsConfig)
    
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

- Gracefully handle `SIGTERM` signals using the method detailed [here](https://github.com/apple/swift-nio-extras/blob/master/Sources/HTTPServerWithQuiescingDemo/main.swift#L59-L69)
- Potentially switch from using `scheduleRepeatedTask` to `scheduleTask`
- Investigate if there is a way to make `JobsConfig`.`storage` not static
- Full documentation in the Vapor docs style
- Potentially ship with a Fluent integration as well
- Look into what it would take to pull this into the main Vapor org
- Tag versions