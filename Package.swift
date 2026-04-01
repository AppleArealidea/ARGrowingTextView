// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ARGrowingTextView",
    defaultLocalization: "en",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "ARGrowingTextView",
            targets: ["ARGrowingTextView"]),
    ],
    dependencies: [
            .package(url: "https://github.com/AppleArealidea/ARMarkdownTextStorage.git", .upToNextMajor(from: "2.0.0"))
        ],
    targets: [
        .target(
            name: "ARGrowingTextView",
            dependencies: ["ARMarkdownTextStorage"],
            path: "ARGrowingTextView/ARGrowingTextView/Source",
            resources: [
                .process("en.lproj"),
                .process("ru.lproj")
            ],
            publicHeadersPath: "./",
            cSettings: [
                .headerSearchPath("./")
            ])
    ]
)
