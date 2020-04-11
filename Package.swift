// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "queues",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "Queues", targets: ["Queues"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0")
    ],
    targets: [
        .target(name: "Queues", dependencies: [
            .product(name: "Vapor", package: "vapor"),
        ]),
        .testTarget(name: "QueueTests", dependencies: [
            .target(name: "Queues"),
            .product(name: "XCTVapor", package: "vapor"),
        ]),
    ]
)
