// swift-tools-version:6.0

import PackageDescription

let atoms = Target.Dependency.product(name: "Atoms", package: "swiftui-atom-properties")

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
            ]
        ),
        .target(name: "ExampleMovieDB", dependencies: [atoms]),
        .testTarget(name: "ExampleMovieDBTests", dependencies: ["ExampleMovieDB"]),
        .target(name: "ExampleMap", dependencies: [atoms]),
        .testTarget(name: "ExampleMapTests", dependencies: ["ExampleMap"]),
        .target(name: "ExampleVoiceMemo", dependencies: [atoms]),
        .testTarget(name: "ExampleVoiceMemoTests", dependencies: ["ExampleVoiceMemo"]),
        .target(name: "ExampleTimeTravel", dependencies: [atoms]),
        .testTarget(name: "ExampleTimeTravelTests", dependencies: ["ExampleTimeTravel"]),
    ]
)
