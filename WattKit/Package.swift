// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "WattKit",
    defaultLocalization: "fr",
    platforms: [.iOS("27.0"), .macOS("27.0")],
    products: [
        .library(name: "WattCore", targets: ["WattCore"]),
        .library(name: "WattUI", targets: ["WattUI"]),
    ],
    targets: [
        .target(name: "WattCore"),
        .target(name: "WattUI", dependencies: ["WattCore"]),
        .testTarget(
            name: "WattCoreTests",
            dependencies: ["WattCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
