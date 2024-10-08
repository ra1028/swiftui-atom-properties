// swift-tools-version:6.0

import PackageDescription

let atoms = Target.Dependency.product(name: "Atoms", package: "swiftui-atom-properties")
let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "iOSExamples",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "iOSApp", targets: ["iOSApp"])
    ],
    dependencies: [
        .package(path: "../../.."),
        .package(path: "../CrossPlatform"),
    ],
    targets: [
        .target(
            name: "iOSApp",
            dependencies: [
                atoms,
                .product(name: "CrossPlatformApp", package: "CrossPlatform"),
                "ExampleMovieDB",
                "ExampleMap",
                "ExampleVoiceMemo",
                "ExampleTimeTravel",
            ],
            swiftSettings: swiftSettings
        ),
        .target(name: "ExampleMovieDB", dependencies: [atoms], swiftSettings: swiftSettings),
        .testTarget(name: "ExampleMovieDBTests", dependencies: ["ExampleMovieDB"], swiftSettings: swiftSettings),
        .target(name: "ExampleMap", dependencies: [atoms], swiftSettings: swiftSettings),
        .testTarget(name: "ExampleMapTests", dependencies: ["ExampleMap"], swiftSettings: swiftSettings),
        .target(name: "ExampleVoiceMemo", dependencies: [atoms], swiftSettings: swiftSettings),
        .testTarget(name: "ExampleVoiceMemoTests", dependencies: ["ExampleVoiceMemo"], swiftSettings: swiftSettings),
        .target(name: "ExampleTimeTravel", dependencies: [atoms], swiftSettings: swiftSettings),
        .testTarget(name: "ExampleTimeTravelTests", dependencies: ["ExampleTimeTravel"], swiftSettings: swiftSettings),
    ]
)
