// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HearthRender",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "HearthRender", targets: ["HearthRender"]),
    ],
    dependencies: [
        .package(path: "../HearthCore"),
    ],
    targets: [
        .target(name: "HearthRender", dependencies: ["HearthCore"]),
    ]
)
