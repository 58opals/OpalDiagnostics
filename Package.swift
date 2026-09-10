// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "OpalDiagnostics",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .watchOS(.v27),
        .tvOS(.v27),
        .visionOS(.v27)
    ],
    products: [
        .library(
            name: "OpalDiagnostics",
            targets: ["OpalDiagnostics"]
        )
    ],
    targets: [
        .target(name: "OpalDiagnostics"),
        .testTarget(
            name: "OpalDiagnosticsTests",
            dependencies: ["OpalDiagnostics"]
        )
    ]
)
