// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HearthUI",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "HearthUI", targets: ["HearthUI"]),
    ],
    targets: [
        .target(name: "HearthUI"),
    ]
)
