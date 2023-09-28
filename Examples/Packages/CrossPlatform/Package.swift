// swift-tools-version:5.8

import PackageDescription

let atoms = Target.Dependency.product(name: "Atoms", package: "swiftui-atom-properties")

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
                "ExampleCounter",
                "ExampleTodo",
            ]
        ),
        .target(name: "ExampleCounter", dependencies: [atoms]),
        .testTarget(name: "ExampleCounterTests", dependencies: ["ExampleCounter"]),
        .target(name: "ExampleTodo", dependencies: [atoms]),
        .testTarget(name: "ExampleTodoTests", dependencies: ["ExampleTodo"]),
    ]
)
