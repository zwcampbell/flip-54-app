// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Flip54WorkoutEngine",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Flip54WorkoutEngine", targets: ["Flip54WorkoutEngine"]),
    ],
    dependencies: [
        .package(path: "../Flip54Core"),
        .package(path: "../Flip54Storage"),
    ],
    targets: [
        .target(
            name: "Flip54WorkoutEngine",
            dependencies: ["Flip54Core", "Flip54Storage"]
        ),
        .testTarget(
            name: "Flip54WorkoutEngineTests",
            dependencies: ["Flip54WorkoutEngine"]
        ),
    ]
)
