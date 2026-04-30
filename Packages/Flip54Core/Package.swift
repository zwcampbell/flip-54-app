// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Flip54Core",
    products: [
        .library(name: "Flip54Core", targets: ["Flip54Core"]),
    ],
    targets: [
        .target(name: "Flip54Core"),
        .testTarget(name: "Flip54CoreTests", dependencies: ["Flip54Core"]),
    ]
)
