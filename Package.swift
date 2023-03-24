// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CornucopiaSUI",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "CornucopiaSUI",
            targets: ["CornucopiaSUI"]),
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
            dependencies: ["CornucopiaSUI"]),
    ]
)
