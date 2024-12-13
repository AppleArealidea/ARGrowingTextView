// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ARGrowingTextView",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "ARGrowingTextView",
            targets: ["ARGrowingTextView"]),
    ],
    dependencies: [
            .package(url: "https://github.com/AppleArealidea/ARMarkdownTextStorage.git", .upToNextMajor(from: "1.0.0"))
        ],
    targets: [
        .target(
            name: "ARGrowingTextView",
            dependencies: ["ARMarkdownTextStorage"],
            path: "ARGrowingTextView/ARGrowingTextView/Source",
            publicHeadersPath: "./",
            cSettings: [
                .headerSearchPath("./")
            ])
    ]
)
