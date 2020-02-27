// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "queues",
    platforms: [
       .macOS(.v10_14)
    ],
    products: [
        .library(name: "Queues", targets: ["Queues"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta.2")
    ],
    targets: [
        .target(name: "Queues", dependencies: ["Vapor"]),
        .testTarget(name: "QueueTests", dependencies: ["Queues", "XCTVapor"]),
    ]
)
