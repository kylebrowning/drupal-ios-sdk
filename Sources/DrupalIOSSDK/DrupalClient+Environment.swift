//
//  DrupalClient+Environment.swift
//  DrupalIOSSDK — SwiftUI Environment plumbing.
//
//  Usage:
//
//      @main
//      struct MyApp: App {
//          var body: some Scene {
//              WindowGroup {
//                  ContentView()
//                      .environment(\.drupal, .live(baseURL: URL(string: "https://example.com")!))
//              }
//          }
//      }
//
//      struct MyView: View {
//          @Environment(\.drupal) private var drupal
//          var body: some View { ... }
//      }
//

#if canImport(SwiftUI)
import SwiftUI

private struct DrupalClientKey: EnvironmentKey {
    static let defaultValue: DrupalClient = .unimplemented
}

public extension EnvironmentValues {
    /// The Drupal REST client for the current view hierarchy. Defaults to
    /// ``DrupalClient/unimplemented`` so that views using this value without
    /// an injected client surface the mistake loudly.
    var drupal: DrupalClient {
        get { self[DrupalClientKey.self] }
        set { self[DrupalClientKey.self] = newValue }
    }
}
#endif
