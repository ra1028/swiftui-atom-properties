// swift-tools-version:6.0

import PackageDescription

func target(name: String, dependencies: [Target.Dependency] = []) -> Target {
    .target(
        name: name,
        dependencies: [.product(name: "Atoms", package: "swiftui-atom-properties")] + dependencies
    )
}

func testTarget(name: String, dependencies: [Target.Dependency]) -> Target {
    .testTarget(
        name: name,
        dependencies: dependencies
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
