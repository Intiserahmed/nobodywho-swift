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
        // XCFramework distributed via GitHub releases
        .binaryTarget(
            name: "NobodyWhoFFI",
            url: "https://github.com/nobodywho-ooo/nobodywho/releases/download/nobodywho-swift-v0.1.0/NobodyWhoFFI.xcframework.zip",
            checksum: "120b7e51aef498ae958d32a7adb79ab02839e8e8bf3963a0382af1b2b7138626"
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
