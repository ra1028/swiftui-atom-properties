// swift-tools-version:5.6

import PackageDescription

let atoms = Target.Dependency.product(name: "Atoms", package: "swiftui-atomic-architecture")

let package = Package(
    name: "iOSExamples",
    platforms: [
        .iOS(.v15)
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
