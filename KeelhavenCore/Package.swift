// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "KeelhavenCore",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "KeelhavenCore", targets: ["KeelhavenCore"])
    ],
    targets: [
        .target(
            name: "KeelhavenCore",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "KeelhavenCoreTests",
            dependencies: ["KeelhavenCore"],
            resources: [.copy("Fixtures")]
        )
    ]
)
