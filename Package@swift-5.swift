// swift-tools-version:5.10

import PackageDescription

let swiftSettings: [SwiftSetting]

if Context.environment["ENABLE_UPCOMING_FEATURES"] != nil {
    swiftSettings = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InferSendableFromCaptures"),
        .enableUpcomingFeature("DisableOutwardActorInference"),
    ]
}
else {
    swiftSettings = [
        .enableUpcomingFeature("ExistentialAny"),
    ]
}

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
    swiftLanguageVersions: [.v5]
)
