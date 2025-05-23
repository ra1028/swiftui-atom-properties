// swift-tools-version:6.0

import PackageDescription

let swiftSettings: [SwiftSetting]

if Context.environment["ENABLE_UPCOMING_FEATURES"] == "1" {
    swiftSettings = [
        .enableUpcomingFeature("DisableOutwardActorInference"),
        .enableUpcomingFeature("InferSendableFromCaptures"),
        .enableUpcomingFeature("IsolatedDefaultValues"),
        .enableUpcomingFeature("StrictConcurrency"),
        .enableUpcomingFeature("ExistentialAny"),
    ]
}
else {
    swiftSettings = [
        .enableUpcomingFeature("ExistentialAny")
    ]
}

let package = Package(
    name: "swiftui-atom-properties",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
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
