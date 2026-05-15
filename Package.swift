// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "OpalDiagnostics",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2)
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
