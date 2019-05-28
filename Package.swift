// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "jobs",
    products: [
        .library(name: "Jobs", targets: ["Jobs"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0")
    ],
    targets: [
        .target(name: "Jobs", dependencies: ["Vapor"]),
        .testTarget(name: "JobsTests", dependencies: ["Jobs"]),
    ]
)
