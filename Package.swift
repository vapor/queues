// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "Jobs",
    products: [
        .library(
            name: "Jobs",
            targets: ["Jobs"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/apple/swift-nio-extras.git", .upToNextMinor(from: "0.1.0"))
    ],
    targets: [
        .target(
            name: "Jobs",
            dependencies: ["Vapor", "NIOExtras"]),
        .testTarget(
            name: "JobsTests",
            dependencies: ["Jobs"]),
    ]
)
