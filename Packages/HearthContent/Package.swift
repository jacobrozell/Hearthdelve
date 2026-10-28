// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HearthContent",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "HearthContent", targets: ["HearthContent"]),
    ],
    dependencies: [
        .package(path: "../HearthCore"),
    ],
    targets: [
        .target(name: "HearthContent", dependencies: ["HearthCore"]),
        .testTarget(name: "HearthContentTests", dependencies: ["HearthContent"]),
    ]
)
