// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "dev-tools",
    dependencies: [
        .package(name: "swiftui-atom-properties", path: ".."),
        .package(url: "https://github.com/apple/swift-docc-plugin", exact: "1.3.0"),
        .package(url: "https://github.com/apple/swift-format.git", exact: "509.0.0"),
        .package(url: "https://github.com/yonaskolb/XcodeGen.git", exact: "2.40.1"),
    ]
)
