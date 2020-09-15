// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Connectivity",
    platforms: [
        .iOS(.v9),
        .tvOS(.v9)
    ],
    products: [
        .library(
            name: "Connectivity",
            targets: ["Connectivity"]
        )
    ],
    targets: [
        .target(
            name: "Connectivity",
            dependencies: ["Reachability"],
            path: "Connectivity/Classes",
            exclude: ["Reachability"],
            swiftSettings: [.define("IMPORT_REACHABILITY")]
        ),
        .target(
            name: "Reachability",
            dependencies: [],
            path: "Connectivity/Classes/Reachability",
            publicHeadersPath: ""
        )
    ]
)
