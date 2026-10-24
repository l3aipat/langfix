// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LangFix",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .target(name: "LangFixCore"),
        .executableTarget(name: "LangFix", dependencies: ["LangFixCore", .product(name: "Sparkle", package: "Sparkle")]),
        .executableTarget(name: "check-layout", dependencies: ["LangFixCore"]),
        .executableTarget(name: "type-keys", dependencies: ["LangFixCore"]),
        .testTarget(name: "LangFixCoreTests", dependencies: ["LangFixCore"]),
    ]
)
