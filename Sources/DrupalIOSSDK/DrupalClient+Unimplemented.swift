//
//  DrupalClient+Unimplemented.swift
//  DrupalIOSSDK — "loud failure" client used as the SwiftUI Environment
//  default. Any call site that reaches for the Drupal client without having
//  injected a real one will throw a clearly-labelled `DrupalError.unimplemented`
//  instead of silently doing nothing.
//

import Foundation

public extension DrupalClient {

    /// The default value stored on `EnvironmentValues.drupal`. Every closure
    /// throws `DrupalError.unimplemented(<method>)` so missing DI is caught at
    /// the call site with a clear message.
    static let unimplemented = DrupalClient(
        login:             { _, _ in throw DrupalError.unimplemented("DrupalClient.login") },
        logout:            { throw DrupalError.unimplemented("DrupalClient.logout") },
        refreshCSRFToken:  { throw DrupalError.unimplemented("DrupalClient.refreshCSRFToken") },
        setAuthentication: { _ in assertionFailure("DrupalClient.setAuthentication is unimplemented") },
        isLoggedIn:        { false },
        csrfToken:         { nil },
        get:               { _, _, _ in throw DrupalError.unimplemented("DrupalClient.get") },
        create:            { _, _ in throw DrupalError.unimplemented("DrupalClient.create") },
        update:            { _, _, _ in throw DrupalError.unimplemented("DrupalClient.update") },
        delete:            { _, _ in throw DrupalError.unimplemented("DrupalClient.delete") },
        view:              { _, _ in throw DrupalError.unimplemented("DrupalClient.view") },
        request:           { _, _, _, _ in throw DrupalError.unimplemented("DrupalClient.request") }
    )

    /// An in-memory mock useful for SwiftUI previews and unit tests. Returns
    /// empty `Data` for all network calls and reports a stubbed logged-in
    /// state that you can flip via the `initiallyLoggedIn` parameter.
    static func mock(initiallyLoggedIn: Bool = false) -> DrupalClient {
        let state = MockState(isLoggedIn: initiallyLoggedIn)
        return DrupalClient(
            login: { username, _ in
                state.setLoggedIn(true)
                return LoginResponse(
                    csrfToken: "mock-csrf",
                    logoutToken: "mock-logout",
                    currentUser: .init(uid: "1", name: username, roles: ["authenticated"])
                )
            },
            logout:            { state.setLoggedIn(false) },
            refreshCSRFToken:  { "mock-csrf" },
            setAuthentication: { _ in },
            isLoggedIn:        { state.isLoggedIn },
            csrfToken:         { "mock-csrf" },
            get:               { _, _, _ in Data() },
            create:            { _, _ in Data() },
            update:            { _, _, _ in Data() },
            delete:            { _, _ in },
            view:              { _, _ in Data("[]".utf8) },
            request:           { _, _, _, _ in Data() }
        )
    }
}

private final class MockState: @unchecked Sendable {
    private let lock = NSLock()
    private var _isLoggedIn: Bool
    init(isLoggedIn: Bool) { self._isLoggedIn = isLoggedIn }
    var isLoggedIn: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isLoggedIn
    }
    func setLoggedIn(_ v: Bool) {
        lock.lock(); _isLoggedIn = v; lock.unlock()
    }
}
