// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftMistralCoreML",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "SwiftMistralCoreML",
            targets: ["SwiftMistralCoreML"]),
    ],
    targets: [
        .target(
            name: "SwiftMistralCoreML",
            resources: [
                .process("Data/tokenizer.json"),
                .process("Data/tokenizer_config.json"),
            ]
        ),
        .testTarget(
            name: "SwiftMistralCoreMLTests",
            dependencies: ["SwiftMistralCoreML"]
        ),
    ]
)
