// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "dev-tools",
    dependencies: [
        .package(name: "swiftui-atom-properties", path: ".."),
        .package(url: "https://github.com/apple/swift-docc-plugin", exact: "1.4.3"),
        .package(url: "https://github.com/apple/swift-format.git", exact: "510.1.0"),
        .package(url: "https://github.com/yonaskolb/XcodeGen.git", exact: "2.42.0"),
    ]
)
