// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Cawenda",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "Cawenda",
            targets: ["Cawenda"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Cawenda",
            dependencies: [],
            path: "Cawenda"
        ),
        .testTarget(
            name: "CawendaTests",
            dependencies: ["Cawenda"],
            path: "CawendaTests"
        ),
    ]
)
