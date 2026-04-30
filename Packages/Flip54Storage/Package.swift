// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Flip54Storage",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Flip54Storage", targets: ["Flip54Storage"]),
    ],
    dependencies: [
        .package(path: "../Flip54Core"),
    ],
    targets: [
        .target(
            name: "Flip54Storage",
            dependencies: ["Flip54Core"]
        ),
        .testTarget(
            name: "Flip54StorageTests",
            dependencies: ["Flip54Storage"]
        ),
    ]
)
