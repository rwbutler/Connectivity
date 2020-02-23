// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Connectivity",
    platforms: [
        .iOS("8.3"),
        .tvOS(.v9)
    ],
    products: [
        .library(
            name: "Connectivity",
            targets: ["Connectivity"]
        )
    ],
    dependencies: [
    .package(url: "https://github.com/ashleymills/Reachability.swift", .branch("master"))
  ],
    targets: [
        .target(
            name: "Connectivity",
            path: "Connectivity/Classes",
            swiftSettings: [.define("IMPORT_REACHABILITY")]
        )
    ]
)
