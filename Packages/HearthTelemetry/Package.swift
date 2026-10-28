// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HearthTelemetry",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "HearthTelemetry", targets: ["HearthTelemetry"]),
    ],
    targets: [
        .target(name: "HearthTelemetry"),
        .testTarget(name: "HearthTelemetryTests", dependencies: ["HearthTelemetry"]),
    ]
)
