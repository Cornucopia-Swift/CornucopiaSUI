// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "CornucopiaSUI",
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
    ],
    targets: [
        .target(
            name: "CornucopiaSUI",
            dependencies: [
                "CornucopiaCore",
                "SFSafeSymbols",
            ]
        ),
        .testTarget(
            name: "CornucopiaSUITests",
            dependencies: ["CornucopiaSUI"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
