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
        // XCFramework distributed via GitHub releases from the main nobodywho repo
        .binaryTarget(
            name: "NobodyWhoFFI",
            url: "https://github.com/Intiserahmed/nobodywho/releases/download/v0.1.0/NobodyWhoFFI.xcframework.zip",
            checksum: "51d0103b8d63c9360bfb2d2d08017bd19eac45fc12de7fa29e68582f4366efb3"
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
