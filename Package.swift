// swift-tools-version:6.0

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "swiftui-atom-properties",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7),
    ],
    products: [
        .library(name: "Atoms", targets: ["Atoms"])
    ],
    targets: [
        .target(
            name: "Atoms",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "AtomsTests",
            dependencies: ["Atoms"],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v5, .v6]
)
