// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "KeelhavenCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "KeelhavenCore", targets: ["KeelhavenCore"])
    ],
    targets: [
        .target(name: "KeelhavenCore"),
        .testTarget(
            name: "KeelhavenCoreTests",
            dependencies: ["KeelhavenCore"],
            resources: [.copy("Fixtures")]
        )
    ]
)
