// swift-tools-version:5.10

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
        .target(
            name: "Atoms"
        ),
        .testTarget(
            name: "AtomsTests",
            dependencies: ["Atoms"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
