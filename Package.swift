// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "jobs",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "Jobs", targets: ["Jobs"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta.2")
    ],
    targets: [
        .target(name: "Jobs", dependencies: ["Vapor"]),
        .testTarget(name: "JobsTests", dependencies: ["Jobs", "XCTVapor"]),
    ]
)
