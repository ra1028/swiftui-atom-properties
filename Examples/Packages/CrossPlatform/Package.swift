// swift-tools-version:5.6

import PackageDescription

let atoms = Target.Dependency.product(name: "Atoms", package: "swiftui-atomic-architecture")

let package = Package(
    name: "CrossPlatformExamples",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7),
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
