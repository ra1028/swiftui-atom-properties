// swift-tools-version:5.9

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .unsafeFlags(["-Xfrontend", "-strict-concurrency=complete"]),
    .unsafeFlags(["-Xfrontend", "-enable-actor-data-race-checks"]),
]

func target(name: String, dependencies: [Target.Dependency] = []) -> Target {
    .target(
        name: name,
        dependencies: [.product(name: "Atoms", package: "swiftui-atom-properties")] + dependencies,
        swiftSettings: swiftSettings
    )
}

func testTarget(name: String, dependencies: [Target.Dependency]) -> Target {
    .testTarget(
        name: name,
        dependencies: dependencies,
        swiftSettings: swiftSettings
    )
}

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
        target(
            name: "iOSApp",
            dependencies: [
                .product(name: "CrossPlatformApp", package: "CrossPlatform"),
                "ExampleMovieDB",
                "ExampleMap",
                "ExampleVoiceMemo",
                "ExampleTimeTravel",
            ]
        ),
        target(name: "ExampleMovieDB"),
        testTarget(name: "ExampleMovieDBTests", dependencies: ["ExampleMovieDB"]),
        target(name: "ExampleMap"),
        testTarget(name: "ExampleMapTests", dependencies: ["ExampleMap"]),
        target(name: "ExampleVoiceMemo"),
        testTarget(name: "ExampleVoiceMemoTests", dependencies: ["ExampleVoiceMemo"]),
        target(name: "ExampleTimeTravel"),
        testTarget(name: "ExampleTimeTravelTests", dependencies: ["ExampleTimeTravel"]),
    ]
)
