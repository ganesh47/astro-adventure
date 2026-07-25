// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AstroAdventureKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .tvOS(.v26),
        .macOS(.v15),
    ],
    products: [
        .library(name: "AstroGameCore", targets: ["AstroGameCore"]),
        .library(name: "AstroContent", targets: ["AstroContent"]),
        .library(name: "AstroServices", targets: ["AstroServices"]),
        .library(name: "AstroWorld", targets: ["AstroWorld"]),
        .library(name: "AstroUI", targets: ["AstroUI"]),
    ],
    targets: [
        .target(name: "AstroGameCore"),
        .target(
            name: "AstroContent",
            dependencies: ["AstroGameCore"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "AstroServices",
            dependencies: ["AstroGameCore"]
        ),
        .target(
            name: "AstroWorld",
            dependencies: ["AstroGameCore"]
        ),
        .target(
            name: "AstroUI",
            dependencies: [
                "AstroContent",
                "AstroGameCore",
                "AstroServices",
                "AstroWorld",
            ]
        ),
        .testTarget(
            name: "AstroGameCoreTests",
            dependencies: ["AstroGameCore"]
        ),
        .testTarget(
            name: "AstroContentTests",
            dependencies: ["AstroContent", "AstroGameCore"]
        ),
        .testTarget(
            name: "AstroServicesTests",
            dependencies: ["AstroGameCore", "AstroServices"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
