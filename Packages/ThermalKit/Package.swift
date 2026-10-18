// swift-tools-version: 6.4

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .treatAllWarnings(as: .error),
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "ThermalKit",
    defaultLocalization: "en",
    platforms: [.macOS("27.0")],
    products: [
        .library(name: "ThermalCore", targets: ["ThermalCore"]),
        .library(name: "ThermalPlatform", targets: ["ThermalPlatform"]),
        .library(name: "ThermalUI", targets: ["ThermalUI"]),
    ],
    targets: [
        .target(
            name: "ThermalCore",
            resources: [.process("Resources")],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "ThermalPlatform",
            dependencies: ["ThermalCore"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "ThermalUI",
            dependencies: ["ThermalCore"],
            resources: [.process("Resources")],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ThermalCoreTests",
            dependencies: ["ThermalCore"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ThermalPlatformTests",
            dependencies: ["ThermalCore", "ThermalPlatform"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ThermalUITests",
            dependencies: ["ThermalCore", "ThermalUI"],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)
