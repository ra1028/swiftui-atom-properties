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
        target(
            name: "CrossPlatformApp",
            dependencies: [
                "ExampleCounter",
                "ExampleTodo",
            ]
        ),
        target(name: "ExampleCounter"),
        testTarget(name: "ExampleCounterTests", dependencies: ["ExampleCounter"]),
        target(name: "ExampleTodo"),
        testTarget(name: "ExampleTodoTests", dependencies: ["ExampleTodo"]),
    ]
)
