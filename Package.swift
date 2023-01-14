// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "queues",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "Queues", targets: ["Queues"]),
        .library(name: "XCTQueues", targets: ["XCTQueues"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.33.0"),
        .package(url: "https://github.com/apple/swift-metrics.git", "1.0.0" ..< "3.0.0")
    ],
    targets: [
        .target(name: "Queues", dependencies: [
            .product(name: "Vapor", package: "vapor"),
            .product(name: "NIOCore", package: "swift-nio"),
            .product(name: "Metrics", package: "swift-metrics"),
        ]),
        .target(name: "XCTQueues", dependencies: [
            .target(name: "Queues")
        ]),
        .testTarget(name: "QueuesTests", dependencies: [
            .target(name: "Queues"),
            .product(name: "XCTVapor", package: "vapor"),
            .target(name: "XCTQueues")
        ]),
    ]
)
