// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "OpalDiagnostics",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .watchOS(.v26),
        .tvOS(.v26),
        .visionOS(.v26)
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
