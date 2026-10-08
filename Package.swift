// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Cawernda",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "Cawernda",
            targets: ["Cawernda"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Cawernda",
            dependencies: [],
            path: "Cawernda"
        ),
        .testTarget(
            name: "CawerndaTests",
            dependencies: ["Cawernda"],
            path: "CawerndaTests"
        ),
    ]
)
