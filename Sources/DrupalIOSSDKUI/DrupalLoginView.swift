//
//  DrupalLoginView.swift
//  DrupalIOSSDKUI — a SwiftUI username/password form that drives the
//  injected ``DrupalClient``'s `login` closure.
//

#if canImport(SwiftUI)
import SwiftUI
import DrupalIOSSDK

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct DrupalLoginView: View {

    @Environment(\.drupal) private var drupal

    @State private var username: String
    @State private var password: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?

    private let onSuccess: (LoginResponse) -> Void
    private let onCancel: (() -> Void)?

    public init(
        prefilledUsername: String = "",
        onSuccess: @escaping (LoginResponse) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self._username = State(initialValue: prefilledUsername)
        self.onSuccess = onSuccess
        self.onCancel = onCancel
    }

    public var body: some View {
        #if os(iOS)
        Form {
            credentialsSection
            actionsSection
            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Sign in")
        #else
        VStack(spacing: 16) {
            credentialsSection
            actionsSection
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
        }
        .padding()
        #endif
    }

    private var credentialsSection: some View {
        Section("Credentials") {
            TextField("Username", text: $username)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                #endif
            SecureField("Password", text: $password)
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                Task { await submit() }
            } label: {
                HStack {
                    if isSubmitting { ProgressView().controlSize(.small) }
                    Text("Sign in").frame(maxWidth: .infinity)
                }
            }
            .disabled(username.isEmpty || password.isEmpty || isSubmitting)

            if let onCancel {
                Button("Cancel", role: .cancel, action: onCancel)
            }
        }
    }

    @MainActor
    private func submit() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let response = try await drupal.login(username, password)
            onSuccess(response)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
#endif
