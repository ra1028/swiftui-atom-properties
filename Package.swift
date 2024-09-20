// swift-tools-version:6.0

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
    swiftLanguageModes: [.v6]
)

if ProcessInfo.processInfo.environment["DEVELOPMENT"] != nil {
    for target in package.targets {
        target.swiftSettings = [
            .unsafeFlags(["-Xfrontend", "-strict-concurrency=complete"]),
            .unsafeFlags(["-Xfrontend", "-enable-actor-data-race-checks"]),
        ]
    }
}
