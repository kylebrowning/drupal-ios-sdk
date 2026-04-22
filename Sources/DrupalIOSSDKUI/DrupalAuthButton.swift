//
//  DrupalAuthButton.swift
//  DrupalIOSSDKUI — a SwiftUI button that reflects the injected Drupal
//  client's logged-in state and triggers logout automatically when tapped
//  while authenticated.
//

#if canImport(SwiftUI)
import SwiftUI
import DrupalIOSSDK

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct DrupalAuthButton: View {

    @Environment(\.drupal) private var drupal

    @State private var isLoggedIn: Bool = false
    @State private var isWorking: Bool = false

    private let onLoginTap: () -> Void
    private let onLogout: (Result<Void, Error>) -> Void
    private let loginLabel: String
    private let logoutLabel: String

    public init(
        loginLabel: String = "Login",
        logoutLabel: String = "Logout",
        onLoginTap: @escaping () -> Void,
        onLogout: @escaping (Result<Void, Error>) -> Void = { _ in }
    ) {
        self.loginLabel = loginLabel
        self.logoutLabel = logoutLabel
        self.onLoginTap = onLoginTap
        self.onLogout = onLogout
    }

    public var body: some View {
        Button {
            guard !isWorking else { return }
            if isLoggedIn {
                Task { await performLogout() }
            } else {
                onLoginTap()
            }
        } label: {
            HStack(spacing: 6) {
                if isWorking {
                    ProgressView().controlSize(.small)
                }
                Text(isLoggedIn ? logoutLabel : loginLabel)
            }
        }
        .disabled(isWorking)
        .onAppear { isLoggedIn = drupal.isLoggedIn() }
        .onReceive(NotificationCenter.default.publisher(for: .drupalDidLogin))  { _ in isLoggedIn = true }
        .onReceive(NotificationCenter.default.publisher(for: .drupalDidLogout)) { _ in isLoggedIn = false }
    }

    @MainActor
    private func performLogout() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await drupal.logout()
            onLogout(.success(()))
        } catch {
            onLogout(.failure(error))
        }
    }
}
#endif
