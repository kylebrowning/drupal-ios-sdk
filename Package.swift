// swift-tools-version:5.9
import PackageDescription

// Waterwheel 5.x ships as a single Swift module. The iOS-only UI helpers
// are wrapped in `#if os(iOS)` guards so the module still builds for
// macOS, tvOS, and watchOS using only the core networking layer.
let package = Package(
    name: "Waterwheel",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(name: "Waterwheel", targets: ["Waterwheel"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Waterwheel",
            path: "Sources",
            exclude: [
                "Info-iOS.plist",
                "Info-macOS.plist",
                "Info-tvOS.plist",
                "Info-watchOS.plist",
                "waterwheel.h"
            ],
            sources: [
                "Shared",
                "iOS"
            ]
        )
    ]
)
