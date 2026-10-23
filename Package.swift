// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LangFix",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "LangFixCore"),
        .executableTarget(name: "LangFix", dependencies: ["LangFixCore"]),
        .executableTarget(name: "check-layout", dependencies: ["LangFixCore"]),
        .executableTarget(name: "type-keys", dependencies: ["LangFixCore"]),
        .testTarget(name: "LangFixCoreTests", dependencies: ["LangFixCore"]),
    ]
)
