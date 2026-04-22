//
//  ContentView.swift
//  DrupalIOSSDKDemo-iOS
//

import SwiftUI
import DrupalIOSSDK
import DrupalIOSSDKUI

struct ContentView: View {

    @Environment(\.drupal) private var drupal

    @State private var isLoggedIn: Bool = false
    @State private var isPresentingLogin: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section("Authentication") {
                    HStack {
                        Text(isLoggedIn ? "Signed in" : "Signed out")
                        Spacer()
                        DrupalAuthButton(
                            onLoginTap: { isPresentingLogin = true },
                            onLogout: { result in
                                if case .failure(let error) = result {
                                    print("logout failed:", error.localizedDescription)
                                }
                            }
                        )
                    }
                }

                Section("Browse") {
                    NavigationLink("Frontpage view") {
                        FrontpageView()
                    }
                    NavigationLink("Fetch node 1") {
                        NodeDetailView(nodeId: "1")
                    }
                }
            }
            .navigationTitle("Drupal iOS SDK")
            .sheet(isPresented: $isPresentingLogin) {
                NavigationStack {
                    DrupalLoginView(
                        prefilledUsername: "demo",
                        onSuccess: { _ in isPresentingLogin = false },
                        onCancel: { isPresentingLogin = false }
                    )
                }
            }
            .onAppear { isLoggedIn = drupal.isLoggedIn() }
            .onReceive(NotificationCenter.default.publisher(for: .drupalDidLogin))  { _ in isLoggedIn = true }
            .onReceive(NotificationCenter.default.publisher(for: .drupalDidLogout)) { _ in isLoggedIn = false }
        }
    }
}

// MARK: - Frontpage view

struct FrontpageRow: Decodable, Identifiable {
    let nid: String?
    let title: String?
    let body: String?
    let type: String?
    let created: String?

    var id: String { nid ?? UUID().uuidString }
}

struct FrontpageView: View {
    var body: some View {
        DrupalViewList<FrontpageRow, AnyView>(viewPath: "frontpage") { row in
            AnyView(
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.title ?? "Untitled").font(.headline)
                    if let type = row.type {
                        Text(type).font(.caption).foregroundStyle(.secondary)
                    }
                }
            )
        }
        .navigationTitle("Frontpage")
    }
}

// MARK: - Raw node fetch

struct NodeDetailView: View {

    @Environment(\.drupal) private var drupal
    let nodeId: String

    @State private var text: String = "Loading…"

    var body: some View {
        ScrollView {
            Text(text)
                .font(.system(.body, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Node \(nodeId)")
        .task {
            do {
                let data = try await drupal.get(.node, nodeId, [:])
                text = String(data: data, encoding: .utf8) ?? "<binary>"
            } catch {
                text = "Error: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.drupal, .mock(initiallyLoggedIn: false))
}
