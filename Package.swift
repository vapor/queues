// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "queues",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "Queues", targets: ["Queues"]),
        .library(name: "XCTQueues", targets: ["XCTQueues"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.101.1"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.53.0"),
    ],
    targets: [
        .target(name: "Queues", dependencies: [
            .product(name: "Vapor", package: "vapor"),
            .product(name: "NIOCore", package: "swift-nio"),
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
