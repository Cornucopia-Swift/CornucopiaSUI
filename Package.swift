// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "CornucopiaSUI",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "CornucopiaSUI",
            targets: ["CornucopiaSUI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Cornucopia-Swift/CornucopiaCore", branch: "master"),
    ],
    targets: [
        .target(
            name: "CornucopiaSUI",
            dependencies: [
                "CornucopiaCore",
            ]
        ),
        .testTarget(
            name: "CornucopiaSUITests",
            dependencies: ["CornucopiaSUI"]
        ),
    ]
)
