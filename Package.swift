// swift-tools-version:5.9
import PackageDescription

// Drupal iOS SDK — Swift SDK for the Drupal 10 / 11 RESTful Web Services API.
//
// Ships two products:
//   * DrupalIOSSDK   — pure-Foundation core (works on iOS, macOS, tvOS, watchOS).
//   * DrupalIOSSDKUI — iOS-only UIKit helpers: auth button, login VC, views.
let package = Package(
    name: "DrupalIOSSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(name: "DrupalIOSSDK",   targets: ["DrupalIOSSDK"]),
        .library(name: "DrupalIOSSDKUI", targets: ["DrupalIOSSDKUI"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DrupalIOSSDK",
            path: "Sources/DrupalIOSSDK",
            exclude: [
                "DrupalIOSSDK.h",
                "Info-iOS.plist",
                "Info-macOS.plist",
                "Info-tvOS.plist",
                "Info-watchOS.plist"
            ]
        ),
        .target(
            name: "DrupalIOSSDKUI",
            dependencies: ["DrupalIOSSDK"],
            path: "Sources/DrupalIOSSDKUI"
        )
    ]
)
