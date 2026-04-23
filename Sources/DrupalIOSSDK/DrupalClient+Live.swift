//
//  DrupalClient+Live.swift
//  DrupalIOSSDK — the real `URLSession`-backed implementation.
//

import Foundation

public extension DrupalClient {

    /// A live client that talks to the Drupal site at `baseURL`.
    ///
    /// The returned client owns a mutable auth state (CSRF / logout tokens,
    /// current `Authentication` mode) held by a private internal reference
    /// so that passing the struct around by value still shares session state.
    /// - Parameters:
    ///   - baseURL: The Drupal site's base URL, e.g. `https://example.com`.
    ///   - authentication: Initial authentication mode. Defaults to `.none`.
    ///     A successful `login(...)` call automatically promotes this to
    ///     `.cookie`.
    ///   - urlSession: The `URLSession` used for every request. Defaults to
    ///     a session configured with `HTTPCookieStorage.shared`.
    ///   - userDefaults: Where the CSRF and logout tokens are persisted
    ///     across app launches. Defaults to `.standard`.
    static func live(
        baseURL: URL,
        authentication: Authentication = .none,
        urlSession: URLSession? = nil,
        userDefaults: UserDefaults = .standard
    ) -> DrupalClient {
        let core = DrupalCore(
            baseURL: baseURL,
            authentication: authentication,
            urlSession: urlSession ?? .drupalDefault(),
            userDefaults: userDefaults
        )
        return DrupalClient(
            login:             { try await core.login(username: $0, password: $1) },
            logout:            { try await core.logout() },
            refreshCSRFToken:  { try await core.refreshCSRFToken() },
            setAuthentication: { core.setAuthentication($0) },
            isLoggedIn:        { core.isLoggedIn },
            csrfToken:         { core.csrfToken },
            get:               { try await core.perform(method: "GET",    entity: $0, id: $1,   query: $2, body: nil) },
            create:            { try await core.perform(method: "POST",   entity: $0, id: nil,  query: ["_format": "json"], body: $1, isCreate: true) },
            update:            { try await core.perform(method: "PATCH",  entity: $0, id: $1,   query: ["_format": "json"], body: $2) },
            delete:            { _ = try await core.perform(method: "DELETE", entity: $0, id: $1, query: ["_format": "json"], body: nil) },
            view:              { try await core.viewRequest(path: $0, query: $1) },
            request:           { try await core.rawRequest(path: $0, method: $1, query: $2, body: $3) }
        )
    }
}

private extension URLSession {
    static func drupalDefault() -> URLSession {
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = HTTPCookieStorage.shared
        return URLSession(configuration: config)
    }
}

// MARK: - DrupalCore — internal mutable state + HTTP plumbing

final class DrupalCore: @unchecked Sendable {

    private let baseURL: URL
    private let session: URLSession
    private let defaults: UserDefaults
    private let lock = NSLock()

    private var _authentication: Authentication
    private var _csrfToken: String?
    private var _logoutToken: String?

    private enum Keys {
        static let csrfToken   = "drupal.csrfToken"
        static let logoutToken = "drupal.logoutToken"
        static let isLoggedIn  = "drupal.isLoggedIn"
    }

    init(baseURL: URL,
         authentication: Authentication,
         urlSession: URLSession,
         userDefaults: UserDefaults) {
        self.baseURL = baseURL
        self.session = urlSession
        self.defaults = userDefaults
        self._authentication = authentication
        self._csrfToken = userDefaults.string(forKey: Keys.csrfToken)
        self._logoutToken = userDefaults.string(forKey: Keys.logoutToken)
    }

    // MARK: Public surface used by the live client

    var isLoggedIn: Bool { defaults.bool(forKey: Keys.isLoggedIn) }

    var csrfToken: String? { lock.withDrupalLock { _csrfToken } }

    func setAuthentication(_ auth: Authentication) {
        lock.withDrupalLock { _authentication = auth }
        if case .none = auth {
            defaults.set(false, forKey: Keys.isLoggedIn)
        } else {
            defaults.set(true, forKey: Keys.isLoggedIn)
        }
    }

    func login(username: String, password: String) async throws -> LoginResponse {
        let url = try endpoint("user/login", query: ["_format": "json"])
        let body = try JSONEncoder().encode(["name": username, "pass": password])

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = body

        NotificationCenter.default.post(name: .drupalDidStartRequest, object: nil)
        defer { NotificationCenter.default.post(name: .drupalDidFinishRequest, object: nil) }

        let (data, response) = try await session.data(for: req)
        try Self.validate(response: response, data: data)
        let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)

        lock.withDrupalLock {
            _authentication = .cookie
            _csrfToken = decoded.csrfToken
            _logoutToken = decoded.logoutToken
        }
        defaults.set(decoded.csrfToken, forKey: Keys.csrfToken)
        defaults.set(decoded.logoutToken, forKey: Keys.logoutToken)
        defaults.set(true, forKey: Keys.isLoggedIn)

        NotificationCenter.default.post(name: .drupalDidLogin, object: nil)
        return decoded
    }

    func logout() async throws {
        let token = lock.withDrupalLock { _logoutToken } ?? ""
        let url = try endpoint("user/logout", query: ["_format": "json", "token": token])

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        applyAuth(to: &req, isMutation: false)

        NotificationCenter.default.post(name: .drupalDidStartRequest, object: nil)
        defer { NotificationCenter.default.post(name: .drupalDidFinishRequest, object: nil) }

        let (data, response) = try await session.data(for: req)
        try Self.validate(response: response, data: data)

        lock.withDrupalLock {
            _authentication = .none
            _csrfToken = nil
            _logoutToken = nil
        }
        defaults.removeObject(forKey: Keys.csrfToken)
        defaults.removeObject(forKey: Keys.logoutToken)
        defaults.set(false, forKey: Keys.isLoggedIn)

        if let cookies = HTTPCookieStorage.shared.cookies(for: baseURL) {
            cookies.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
        }

        NotificationCenter.default.post(name: .drupalDidLogout, object: nil)
    }

    @discardableResult
    func refreshCSRFToken() async throws -> String {
        let url = try endpoint("session/token")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("text/plain", forHTTPHeaderField: "Accept")
        applyAuth(to: &req, isMutation: false)

        let (data, response) = try await session.data(for: req)
        try Self.validate(response: response, data: data)

        guard let token = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !token.isEmpty else {
            throw DrupalError.missingCSRFToken
        }
        lock.withDrupalLock { _csrfToken = token }
        defaults.set(token, forKey: Keys.csrfToken)
        return token
    }

    /// Entity-scoped request used by `get` / `create` / `update` / `delete`.
    @discardableResult
    func perform(method: String,
                 entity: EntityType,
                 id: String?,
                 query: [String: String],
                 body: Data?,
                 isCreate: Bool = false) async throws -> Data {
        var effectiveQuery = query
        if effectiveQuery["_format"] == nil {
            effectiveQuery["_format"] = "json"
        }

        let path: String
        if isCreate {
            path = "entity/\(entity.rawValue)"
        } else if let id {
            path = "\(entity.canonicalPath)/\(id)"
        } else {
            path = entity.canonicalPath
        }
        let url = try endpoint(path, query: effectiveQuery)
        return try await perform(method: method, url: url, body: body)
    }

    func viewRequest(path: String, query: [String: String]) async throws -> Data {
        var q = query
        q["_format"] = "json"
        let url = try endpoint(path, query: q)
        return try await perform(method: "GET", url: url, body: nil)
    }

    func rawRequest(path: String,
                    method: String,
                    query: [String: String],
                    body: Data?) async throws -> Data {
        let url = try endpoint(path, query: query)
        return try await perform(method: method, url: url, body: body)
    }

    // MARK: Private

    private func perform(method: String, url: URL, body: Data?) async throws -> Data {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
        }

        let isMutation = !(method == "GET" || method == "HEAD" || method == "OPTIONS")
        if isMutation { try await ensureCSRFToken() }
        applyAuth(to: &req, isMutation: isMutation)

        NotificationCenter.default.post(name: .drupalDidStartRequest, object: nil)
        defer { NotificationCenter.default.post(name: .drupalDidFinishRequest, object: nil) }

        let (data, response) = try await session.data(for: req)
        try Self.validate(response: response, data: data)
        return data
    }

    private func ensureCSRFToken() async throws {
        let token = lock.withDrupalLock { _csrfToken }
        if token == nil || token?.isEmpty == true {
            _ = try await refreshCSRFToken()
        }
    }

    private func applyAuth(to request: inout URLRequest, isMutation: Bool) {
        let auth = lock.withDrupalLock { _authentication }
        switch auth {
        case .none:
            break
        case .cookie:
            if isMutation, let t = lock.withDrupalLock({ _csrfToken }), !t.isEmpty {
                request.setValue(t, forHTTPHeaderField: "X-CSRF-Token")
            }
        case .basic(let user, let pass):
            let raw = "\(user):\(pass)".data(using: .utf8) ?? Data()
            request.setValue("Basic \(raw.base64EncodedString())", forHTTPHeaderField: "Authorization")
        case .bearer(let token):
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func endpoint(_ path: String, query: [String: String] = [:]) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw DrupalError.invalidURL(baseURL.absoluteString)
        }
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let existing = components.path.hasSuffix("/") ? components.path : components.path + "/"
        components.path = existing + trimmed
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else {
            throw DrupalError.invalidURL(components.string ?? path)
        }
        return url
    }

    private static func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw DrupalError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw DrupalError.http(status: http.statusCode, body: data)
        }
    }
}

// MARK: - NSLock convenience

private extension NSLock {
    func withDrupalLock<T>(_ body: () -> T) -> T {
        lock(); defer { unlock() }
        return body()
    }
}
