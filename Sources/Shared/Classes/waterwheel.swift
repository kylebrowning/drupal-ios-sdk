//
//  waterwheel.swift
//
//  Waterwheel 5.x — Swift SDK for the Drupal RESTful Web Services API.
//  Targets Drupal 10 / 11 core REST module. Pure Foundation, no third-party deps.
//
//  Docs: https://www.drupal.org/docs/drupal-apis/restful-web-services-api/restful-web-services-api-overview
//

import Foundation

// MARK: - Public types

/// Content entity types exposed by the Drupal core REST module. Extend as needed.
public enum EntityType: String, Sendable {
    case node
    case comment
    case user
    case taxonomyTerm = "taxonomy_term"
    case mediaItem = "media"
    case file

    /// Canonical URL fragment for the entity type. Most entities have a canonical URL
    /// of `/{type}/{id}`; those that do not fall back to `/entity/{type}/{id}`.
    var canonicalPath: String {
        switch self {
        case .node, .user, .file, .mediaItem:
            return rawValue
        case .comment, .taxonomyTerm:
            return "entity/\(rawValue)"
        }
    }
}

/// Authentication modes supported by the core REST module.
public enum Authentication: Sendable {
    case none
    case cookie
    case basic(username: String, password: String)
    case bearer(token: String)
}

public enum WaterwheelError: Error, LocalizedError {
    case missingBaseURL
    case invalidURL(String)
    case invalidResponse
    case http(status: Int, body: Data?)
    case decoding(Error)
    case missingCSRFToken

    public var errorDescription: String? {
        switch self {
        case .missingBaseURL:
            return "Waterwheel: base URL has not been set. Call Waterwheel.shared.configure(baseURL:)."
        case .invalidURL(let s):
            return "Waterwheel: invalid URL \(s)."
        case .invalidResponse:
            return "Waterwheel: the server returned an invalid response."
        case .http(let status, _):
            return "Waterwheel: HTTP \(status)."
        case .decoding(let e):
            return "Waterwheel: failed to decode response (\(e.localizedDescription))."
        case .missingCSRFToken:
            return "Waterwheel: CSRF token is required for this request but is not available."
        }
    }
}

public struct LoginResponse: Decodable, Sendable {
    public let csrfToken: String?
    public let logoutToken: String?
    public let currentUser: CurrentUser?

    enum CodingKeys: String, CodingKey {
        case csrfToken = "csrf_token"
        case logoutToken = "logout_token"
        case currentUser = "current_user"
    }

    public struct CurrentUser: Decodable, Sendable {
        public let uid: String?
        public let name: String?
        public let roles: [String]?
    }
}

/// Notification names posted on the main queue around request lifecycle events.
public extension Notification.Name {
    static let waterwheelDidLogin        = Notification.Name("waterwheelDidLogin")
    static let waterwheelDidLogout       = Notification.Name("waterwheelDidLogout")
    static let waterwheelDidStartRequest = Notification.Name("waterwheelDidStartRequest")
    static let waterwheelDidFinishRequest = Notification.Name("waterwheelDidFinishRequest")
}

// MARK: - Waterwheel

/// Thread-safe singleton client for talking to a Drupal REST backend.
/// Use `Waterwheel.shared.configure(baseURL:)` once at app launch, then call the
/// async methods on ``Waterwheel``. A closure-based compatibility API is
/// provided in ``WaterwheelCompat`` below.
public final class Waterwheel: @unchecked Sendable {

    public static let shared = Waterwheel()

    private let lock = NSLock()
    private let session: URLSession
    private let defaults = UserDefaults.standard

    private var _baseURL: URL?
    private var _authentication: Authentication = .none
    private var _csrfToken: String?
    private var _logoutToken: String?

    private enum Keys {
        static let baseURL    = "waterwheel.baseURL"
        static let csrfToken  = "waterwheel.csrfToken"
        static let logoutToken = "waterwheel.logoutToken"
        static let isLoggedIn = "waterwheel.isLoggedIn"
        static let basicUser  = "waterwheel.basicUsername"
        static let basicPass  = "waterwheel.basicPassword"
    }

    private init() {
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = HTTPCookieStorage.shared
        self.session = URLSession(configuration: config)

        if let stored = defaults.string(forKey: Keys.baseURL), let url = URL(string: stored) {
            self._baseURL = url
        }
        self._csrfToken = defaults.string(forKey: Keys.csrfToken)
        self._logoutToken = defaults.string(forKey: Keys.logoutToken)

        if let user = defaults.string(forKey: Keys.basicUser),
           let pass = defaults.string(forKey: Keys.basicPass),
           !user.isEmpty {
            self._authentication = .basic(username: user, password: pass)
        }
    }

    // MARK: Configuration

    /// Set the Drupal site's base URL, e.g. `https://example.com`.
    public func configure(baseURL: URL) {
        lock.lock(); defer { lock.unlock() }
        _baseURL = baseURL
        defaults.set(baseURL.absoluteString, forKey: Keys.baseURL)
    }

    /// Select an authentication mode for subsequent requests.
    public func setAuthentication(_ auth: Authentication) {
        lock.lock(); defer { lock.unlock() }
        _authentication = auth
        switch auth {
        case .basic(let u, let p):
            defaults.set(u, forKey: Keys.basicUser)
            defaults.set(p, forKey: Keys.basicPass)
            defaults.set(true, forKey: Keys.isLoggedIn)
        case .none:
            defaults.removeObject(forKey: Keys.basicUser)
            defaults.removeObject(forKey: Keys.basicPass)
            defaults.set(false, forKey: Keys.isLoggedIn)
        default:
            break
        }
    }

    public var baseURL: URL? {
        lock.lock(); defer { lock.unlock() }
        return _baseURL
    }

    public var isLoggedIn: Bool {
        defaults.bool(forKey: Keys.isLoggedIn)
    }

    public var csrfToken: String? {
        lock.lock(); defer { lock.unlock() }
        return _csrfToken
    }

    // MARK: Authentication

    /// Log a user in using the cookie-based `/user/login?_format=json` endpoint.
    /// Stores the returned CSRF + logout tokens. Session cookie is kept by
    /// `HTTPCookieStorage.shared`.
    @discardableResult
    public func login(username: String, password: String) async throws -> LoginResponse {
        let url = try endpoint("user/login", query: ["_format": "json"])
        let body = try JSONEncoder().encode(["name": username, "pass": password])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = body

        NotificationCenter.default.post(name: .waterwheelDidStartRequest, object: nil)
        defer { NotificationCenter.default.post(name: .waterwheelDidFinishRequest, object: nil) }

        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response, data: data)

        let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)

        lock.lock()
        _authentication = .cookie
        _csrfToken = decoded.csrfToken
        _logoutToken = decoded.logoutToken
        defaults.set(decoded.csrfToken, forKey: Keys.csrfToken)
        defaults.set(decoded.logoutToken, forKey: Keys.logoutToken)
        defaults.set(true, forKey: Keys.isLoggedIn)
        lock.unlock()

        NotificationCenter.default.post(name: .waterwheelDidLogin, object: nil)
        return decoded
    }

    /// Log out the current cookie-authenticated user.
    public func logout() async throws {
        let token = lock.withLock { _logoutToken } ?? ""
        let url = try endpoint("user/logout", query: ["_format": "json", "token": token])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyAuth(to: &request, isMutation: false)

        NotificationCenter.default.post(name: .waterwheelDidStartRequest, object: nil)
        defer { NotificationCenter.default.post(name: .waterwheelDidFinishRequest, object: nil) }

        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response, data: data)

        lock.lock()
        _authentication = .none
        _csrfToken = nil
        _logoutToken = nil
        defaults.removeObject(forKey: Keys.csrfToken)
        defaults.removeObject(forKey: Keys.logoutToken)
        defaults.set(false, forKey: Keys.isLoggedIn)
        lock.unlock()

        // Also clear any session cookies for the site.
        if let base = baseURL, let cookies = HTTPCookieStorage.shared.cookies(for: base) {
            cookies.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
        }

        NotificationCenter.default.post(name: .waterwheelDidLogout, object: nil)
    }

    /// Fetch and cache a CSRF token from `/session/token`. Drupal requires this
    /// for any unsafe (POST / PATCH / DELETE) request on a session-authenticated
    /// client.
    @discardableResult
    public func refreshCSRFToken() async throws -> String {
        let url = try endpoint("session/token")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("text/plain", forHTTPHeaderField: "Accept")
        applyAuth(to: &request, isMutation: false)

        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response, data: data)

        guard let token = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !token.isEmpty else {
            throw WaterwheelError.missingCSRFToken
        }

        lock.lock()
        _csrfToken = token
        defaults.set(token, forKey: Keys.csrfToken)
        lock.unlock()
        return token
    }

    // MARK: Entity CRUD

    /// GET `/{entity}/{id}?_format=json`.
    public func get(_ entity: EntityType, id: String, query: [String: String] = [:]) async throws -> Data {
        var q = query
        q["_format"] = "json"
        let url = try endpoint("\(entity.canonicalPath)/\(id)", query: q)
        return try await perform(method: "GET", url: url, body: nil)
    }

    /// POST to `/entity/{type}?_format=json` — the canonical "create" URL.
    public func create<T: Encodable>(_ entity: EntityType, body: T) async throws -> Data {
        let url = try endpoint("entity/\(entity.rawValue)", query: ["_format": "json"])
        let data = try JSONEncoder().encode(body)
        return try await perform(method: "POST", url: url, body: data)
    }

    /// PATCH `/{entity}/{id}?_format=json`.
    public func update<T: Encodable>(_ entity: EntityType, id: String, body: T) async throws -> Data {
        let url = try endpoint("\(entity.canonicalPath)/\(id)", query: ["_format": "json"])
        let data = try JSONEncoder().encode(body)
        return try await perform(method: "PATCH", url: url, body: data)
    }

    /// DELETE `/{entity}/{id}?_format=json`.
    public func delete(_ entity: EntityType, id: String) async throws {
        let url = try endpoint("\(entity.canonicalPath)/\(id)", query: ["_format": "json"])
        _ = try await perform(method: "DELETE", url: url, body: nil)
    }

    // MARK: Generic helpers

    /// Convenience for Views (rest_export) endpoints.
    public func view(at path: String, query: [String: String] = [:]) async throws -> Data {
        var q = query
        q["_format"] = "json"
        let url = try endpoint(path, query: q)
        return try await perform(method: "GET", url: url, body: nil)
    }

    /// Low-level request. Prefer the typed helpers above.
    public func request(path: String,
                        method: String,
                        query: [String: String] = [:],
                        body: Data? = nil) async throws -> Data {
        let url = try endpoint(path, query: query)
        return try await perform(method: method, url: url, body: body)
    }

    /// Decodes the response body directly into a `Decodable` type.
    public func requestDecoded<T: Decodable>(_ type: T.Type,
                                             path: String,
                                             method: String = "GET",
                                             query: [String: String] = [:],
                                             body: Data? = nil) async throws -> T {
        let data = try await request(path: path, method: method, query: query, body: body)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw WaterwheelError.decoding(error)
        }
    }

    // MARK: Private

    private func perform(method: String, url: URL, body: Data?) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }

        let isMutation = !(method == "GET" || method == "HEAD" || method == "OPTIONS")
        if isMutation {
            try await ensureCSRFToken()
        }
        applyAuth(to: &request, isMutation: isMutation)

        NotificationCenter.default.post(name: .waterwheelDidStartRequest, object: nil)
        defer { NotificationCenter.default.post(name: .waterwheelDidFinishRequest, object: nil) }

        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response, data: data)
        return data
    }

    private func ensureCSRFToken() async throws {
        let token = lock.withLock { _csrfToken }
        if token == nil || token?.isEmpty == true {
            _ = try await refreshCSRFToken()
        }
    }

    private func applyAuth(to request: inout URLRequest, isMutation: Bool) {
        let auth = lock.withLock { _authentication }
        switch auth {
        case .none:
            break
        case .cookie:
            if isMutation, let t = lock.withLock({ _csrfToken }), !t.isEmpty {
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
        guard let base = baseURL else { throw WaterwheelError.missingBaseURL }
        guard var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
            throw WaterwheelError.invalidURL(base.absoluteString)
        }
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let existing = components.path.hasSuffix("/") ? components.path : components.path + "/"
        components.path = existing + trimmed
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else {
            throw WaterwheelError.invalidURL(components.string ?? path)
        }
        return url
    }

    private static func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw WaterwheelError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw WaterwheelError.http(status: http.statusCode, body: data)
        }
    }
}

// MARK: - NSLock convenience

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock(); defer { unlock() }
        return body()
    }
}

// MARK: - Closure-based compatibility API (deprecated; bridges pre-5.x callers)

public typealias WaterwheelCompletion = (_ success: Bool, _ data: Data?, _ error: Error?) -> Void

public enum WaterwheelCompat {

    @available(*, deprecated, message: "Use Waterwheel.shared.configure(baseURL:)")
    public static func setDrupalURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        Waterwheel.shared.configure(baseURL: url)
    }

    @available(*, deprecated, message: "Use Waterwheel.shared.setAuthentication(.basic(...))")
    public static func setBasicAuth(username: String, password: String) {
        Waterwheel.shared.setAuthentication(.basic(username: username, password: password))
    }

    @available(*, deprecated, message: "Use `try await Waterwheel.shared.login(username:password:)`")
    public static func login(username: String, password: String, completion: WaterwheelCompletion?) {
        Task {
            do {
                _ = try await Waterwheel.shared.login(username: username, password: password)
                completion?(true, nil, nil)
            } catch {
                completion?(false, nil, error)
            }
        }
    }

    @available(*, deprecated, message: "Use `try await Waterwheel.shared.logout()`")
    public static func logout(completion: WaterwheelCompletion?) {
        Task {
            do {
                try await Waterwheel.shared.logout()
                completion?(true, nil, nil)
            } catch {
                completion?(false, nil, error)
            }
        }
    }

    @available(*, deprecated, message: "Use `try await Waterwheel.shared.get(_:id:)`")
    public static func nodeGet(id: String, completion: WaterwheelCompletion?) {
        Task {
            do {
                let data = try await Waterwheel.shared.get(.node, id: id)
                completion?(true, data, nil)
            } catch {
                completion?(false, nil, error)
            }
        }
    }
}
