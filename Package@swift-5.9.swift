// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "queues",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(name: "Queues", targets: ["Queues"]),
        .library(name: "XCTQueues", targets: ["XCTQueues"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.101.1"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/apple/swift-metrics.git", from: "2.5.0"),
    ],
    targets: [
        .target(
            name: "Queues",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "Metrics", package: "swift-metrics"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "XCTQueues",
            dependencies: [
                .target(name: "Queues"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "QueuesTests",
            dependencies: [
                .target(name: "Queues"),
                .target(name: "XCTQueues"),
                .product(name: "XCTVapor", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableExperimentalFeature("StrictConcurrency=complete"),
] }
