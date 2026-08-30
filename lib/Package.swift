// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "NotejotCore",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "NotejotCore", targets: ["NotejotCore"]),
    ],
    targets: [
        .target(
            name: "NotejotCore",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "NotejotCoreTests",
            dependencies: ["NotejotCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
