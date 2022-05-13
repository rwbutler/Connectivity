// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "linting",
    platforms: [.macOS(.v10_11)],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.48.10"),
    ],
    targets: [.target(name: "linting", path: "")]
)
