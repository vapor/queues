// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "jobs",
    products: [
        .library(name: "Jobs", targets: ["Jobs"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-alpha.1.1")
    ],
    targets: [
        .target(name: "Jobs", dependencies: ["Vapor"]),
        .testTarget(name: "JobsTests", dependencies: ["Jobs"]),
    ]
)
