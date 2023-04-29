// swift-tools-version:5.7

import Foundation
import PackageDescription

let package = Package(
    name: "swiftui-atom-properties",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7),
    ],
    products: [
        .library(name: "Atoms", targets: ["Atoms"])
    ],
    targets: [
        .target(name: "Atoms"),
        .testTarget(
            name: "AtomsTests",
            dependencies: ["Atoms"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)

if ProcessInfo.processInfo.environment["SWIFTUI_ATOM_PROPERTIES_DEVELOPMENT"] != nil {
    package.dependencies.append(contentsOf: [
        .package(url: "https://github.com/apple/swift-docc-plugin", exact: "1.2.0"),
        .package(url: "https://github.com/apple/swift-format.git", exact: "508.0.0"),
        .package(url: "https://github.com/yonaskolb/XcodeGen.git", exact: "2.35.0"),
    ])
}
