// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MonetizationKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "MonetizationKit", targets: ["MonetizationKit"])
    ],
    targets: [
        .target(name: "MonetizationKit", path: "Sources/MonetizationKit"),
        .testTarget(
            name: "MonetizationKitTests",
            dependencies: ["MonetizationKit"],
            path: "Tests/MonetizationKitTests"
        )
    ]
)
