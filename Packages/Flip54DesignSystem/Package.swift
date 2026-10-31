// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Flip54DesignSystem",
    platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v11)],
    products: [
        .library(name: "Flip54DesignSystem", targets: ["Flip54DesignSystem"]),
    ],
    dependencies: [
        .package(path: "../Flip54Core"),
    ],
    targets: [
        .target(
            name: "Flip54DesignSystem",
            dependencies: ["Flip54Core"]
        ),
    ]
)
