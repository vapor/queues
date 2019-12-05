// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "jobs",
    platforms: [
       .macOS(.v10_14)
    ],
    products: [
        .library(name: "Jobs", targets: ["Jobs"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .branch("master"))
    ],
    targets: [
        .target(name: "Jobs", dependencies: ["Vapor"]),
        .testTarget(name: "JobsTests", dependencies: ["Jobs", "XCTVapor"]),
    ]
)
