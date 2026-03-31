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
            path: "Sources/NobodyWho"
        ),
        .binaryTarget(
            name: "NobodyWhoFFI",
            url: "https://github.com/Intiserahmed/nobodywho-swift/releases/download/v2.0.0/NobodyWhoFFI.xcframework.zip",
            checksum: "a849fd80a0e0bf491afbd22b0d5b67cf9d1642ad813ff4e752b30292085f11e1"
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
