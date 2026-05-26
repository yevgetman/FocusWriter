// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FocusWriter",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "FocusWriter", path: "Sources")
    ]
)
