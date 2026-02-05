// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Components",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "Components",
            targets: ["Components"]
        )
    ],
    targets: [
        .target(
            name: "Components",
            dependencies: [],
            path: "Sources/Components"
        )
    ]
)
