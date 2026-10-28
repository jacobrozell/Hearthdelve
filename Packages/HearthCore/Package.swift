// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HearthCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "HearthCore", targets: ["HearthCore"]),
    ],
    targets: [
        .target(name: "HearthCore"),
        .testTarget(name: "HearthCoreTests", dependencies: ["HearthCore"]),
    ]
)
