// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "jobs",
    products: [
        .library(name: "Jobs", targets: ["Jobs"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .branch("master"))
    ],
    targets: [
        .target(name: "Jobs", dependencies: ["Vapor"]),
        .testTarget(name: "JobsTests", dependencies: ["Jobs"]),
    ]
)
