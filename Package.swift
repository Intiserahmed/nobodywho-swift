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
        // System library target that provides C module with type definitions
        .systemLibrary(
            name: "NobodyWhoFFIFFI",
            path: "Sources/NobodyWhoFFIFFI"
        ),
        .target(
            name: "NobodyWho",
            dependencies: [
                "NobodyWhoFFIFFI",
                "NobodyWhoFFI"
            ],
            path: "Sources/NobodyWho",
            linkerSettings: [
                .linkedFramework("NobodyWhoFFI")
            ]
        ),
        // XCFramework distributed via GitHub Releases
        // Update URL and checksum for each release
        .binaryTarget(
            name: "NobodyWhoFFI",
            url: "https://github.com/Intiserahmed/nobodywho-swift/releases/download/v2.1.1/NobodyWhoFFI.xcframework.zip",
            checksum: "45ab26d2d42cb65f41a1aaa9e425da932acf742994b3c96817e2b101596f9c61"
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
