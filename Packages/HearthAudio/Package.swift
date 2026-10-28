// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HearthAudio",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "HearthAudio", targets: ["HearthAudio"]),
    ],
    targets: [
        .target(name: "HearthAudio"),
    ]
)
