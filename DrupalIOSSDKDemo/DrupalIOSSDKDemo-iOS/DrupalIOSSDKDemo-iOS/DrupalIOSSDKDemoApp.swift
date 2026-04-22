//
//  DrupalIOSSDKDemoApp.swift
//  DrupalIOSSDKDemo-iOS
//
//  SwiftUI entry point. Injects a `.live` DrupalClient into the environment
//  at the app root; every child view uses `@Environment(\.drupal)` to reach it.
//

import SwiftUI
import DrupalIOSSDK

@main
struct DrupalIOSSDKDemoApp: App {

    // Point this at your Drupal site. Switching between `.live(...)` and
    // `.mock()` (from DrupalIOSSDK) is a one-line change for previews/tests.
    private static let client: DrupalClient = .live(
        baseURL: URL(string: "https://example.com")!
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.drupal, Self.client)
        }
    }
}
