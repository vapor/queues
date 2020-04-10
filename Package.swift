// swift-tools-version:5.2
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
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0")
    ],
    targets: [
        .target(name: "Queues", dependencies: [
            .product(name: "Vapor", package: "vapor"),
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
