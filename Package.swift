// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Grayskull",
    products: [
        .library(
            name: "Grayskull",
            targets: ["Grayskull"]
        ),
    ],
    targets: [
        // C wrapper around the grayskull header-only library
        .target(
            name: "CGrayskull",
            dependencies: [],
            path: "Sources/CGrayskull",
            exclude: [],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("../../grayskull"),
                .define("GS_API", to: "static inline"),
            ]
        ),

        // Swift wrapper with ergonomic API
        .target(
            name: "Grayskull",
            dependencies: ["CGrayskull"],
            path: "Sources/Grayskull",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .swiftLanguageMode(.v6)
            ]
        ),

        // Tests
        .testTarget(
            name: "GrayskullTests",
            dependencies: ["Grayskull"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ],
    swiftLanguageModes: [.v6],
    cLanguageStandard: .c11
)

// Add WASM support
#if os(WASI)
package.targets.first(where: { $0.name == "CGrayskull" })?.cSettings?.append(
    .define("GS_NO_STDLIB")
)
#endif
