// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "CornucopiaSUI",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v10),
    ],
    products: [
        .library(
            name: "CornucopiaSUI",
            targets: ["CornucopiaSUI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Cornucopia-Swift/CornucopiaCore", branch: "master"),
        .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols", branch: "stable"),
        .package(url: "https://github.com/Automotive-Swift/VIN", branch: "master"),
    ],
    targets: [
        .target(
            name: "CornucopiaSUI",
            dependencies: [
                "CornucopiaCore",
                "SFSafeSymbols",
                "VIN",
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "CornucopiaSUITests",
            dependencies: ["CornucopiaSUI"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
