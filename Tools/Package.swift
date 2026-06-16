// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "dev-tools",
    dependencies: [
        .package(name: "swiftui-atom-properties", path: ".."),
        .package(url: "https://github.com/apple/swift-format.git", exact: "602.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", exact: "1.5.0"),
        .package(url: "https://github.com/yonaskolb/XcodeGen.git", exact: "2.45.4"),
    ]
)
