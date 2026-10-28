// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HearthSimCLI",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(path: "../HearthCore"),
        .package(path: "../HearthContent"),
    ],
    targets: [
        .executableTarget(
            name: "HearthSimCLI",
            dependencies: ["HearthCore", "HearthContent"]
        ),
        .testTarget(name: "HearthSimCLITests", dependencies: ["HearthSimCLI"]),
    ]
)
