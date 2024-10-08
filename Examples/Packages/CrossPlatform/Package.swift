// swift-tools-version:6.0

import PackageDescription

let atoms = Target.Dependency.product(name: "Atoms", package: "swiftui-atom-properties")
let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny")
]

let package = Package(
    name: "CrossPlatformExamples",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .library(name: "CrossPlatformApp", targets: ["CrossPlatformApp"])
    ],
    dependencies: [
        .package(path: "../../..")
    ],
    targets: [
        .target(
            name: "CrossPlatformApp",
            dependencies: [
                atoms,
                "ExampleCounter",
                "ExampleTodo",
            ],
            swiftSettings: swiftSettings
        ),
        .target(name: "ExampleCounter", dependencies: [atoms], swiftSettings: swiftSettings),
        .testTarget(name: "ExampleCounterTests", dependencies: ["ExampleCounter"], swiftSettings: swiftSettings),
        .target(name: "ExampleTodo", dependencies: [atoms], swiftSettings: swiftSettings),
        .testTarget(name: "ExampleTodoTests", dependencies: ["ExampleTodo"], swiftSettings: swiftSettings),
    ]
)
