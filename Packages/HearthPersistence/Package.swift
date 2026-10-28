// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HearthPersistence",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "HearthPersistence", targets: ["HearthPersistence"]),
    ],
    dependencies: [
        .package(path: "../HearthCore"),
    ],
    targets: [
        .target(name: "HearthPersistence", dependencies: ["HearthCore"]),
        .testTarget(name: "HearthPersistenceTests", dependencies: ["HearthPersistence"]),
    ]
)
