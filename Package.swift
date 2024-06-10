// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Connectivity",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12),
        .macOS(.v10_13)
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
            resources: [.copy("../../Example/Pods/Target Support Files/Connectivity-iOS/PrivacyInfo.xcprivacy")],
            swiftSettings: [.define("IMPORT_REACHABILITY")]
        ),
        .target(
            name: "Reachability",
            dependencies: [],
            path: "Connectivity/Classes/Reachability",
            publicHeadersPath: "",
            cSettings: [
                .headerSearchPath("Connectivity/Classes/Reachability")
            ]
        )
    ]
)
