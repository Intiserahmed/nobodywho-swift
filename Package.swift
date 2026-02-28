// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NobodyWho",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "NobodyWho",
            targets: ["NobodyWho"]
        ),
        .executable(
            name: "NobodyWhoTestCLI",
            targets: ["NobodyWhoTestCLI"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NobodyWho",
            dependencies: ["NobodyWhoFFI"],
            path: "Sources/NobodyWho",
            cSettings: [
                .unsafeFlags(["-fmodule-map-file=NobodyWhoFFI.xcframework/macos-arm64_x86_64/NobodyWhoFFI.framework/Modules/module.modulemap"], .when(platforms: [.macOS])),
                .unsafeFlags(["-fmodule-map-file=NobodyWhoFFI.xcframework/ios-arm64_x86_64-simulator/NobodyWhoFFI.framework/Modules/module.modulemap"], .when(platforms: [.iOS], configuration: .debug)),
                .unsafeFlags(["-fmodule-map-file=NobodyWhoFFI.xcframework/ios-arm64/NobodyWhoFFI.framework/Modules/module.modulemap"], .when(platforms: [.iOS], configuration: .release))
            ],
            linkerSettings: [
                .linkedFramework("NobodyWhoFFI")
            ]
        ),
        // XCFramework bundled in the repo for reliable SPM distribution
        .binaryTarget(
            name: "NobodyWhoFFI",
            path: "NobodyWhoFFI.xcframework"
        ),
        .executableTarget(
            name: "NobodyWhoTestCLI",
            dependencies: ["NobodyWho"],
            path: "Sources/NobodyWhoTestCLI"
        ),
        .testTarget(
            name: "NobodyWhoTests",
            dependencies: ["NobodyWho"]
        ),
    ]
)
