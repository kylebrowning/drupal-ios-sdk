//
//  DrupalClient.swift
//  DrupalIOSSDK — a closure-based dependency-injection surface for the
//  Drupal RESTful Web Services API.
//
//  Rather than exposing a singleton, the SDK ships a `struct` whose stored
//  properties are closures. The struct itself *is* the protocol; concrete
//  implementations are just different instances (`.live(baseURL:)`,
//  `.unimplemented`, test doubles, etc.) created by factory functions.
//  Inspired by https://kylebrowning.com/posts/dependency-injection-in-swiftui/
//

import Foundation

/// A value-typed façade over the Drupal REST API. Inject via SwiftUI's
/// Environment (`.environment(\.drupal, .live(baseURL:))`) or pass explicitly
/// into initializers.
public struct DrupalClient: Sendable {

    // MARK: Authentication
    public var login:             @Sendable (_ username: String, _ password: String) async throws -> LoginResponse
    public var logout:            @Sendable () async throws -> Void
    public var refreshCSRFToken:  @Sendable () async throws -> String
    public var setAuthentication: @Sendable (_ auth: Authentication) -> Void
    public var isLoggedIn:        @Sendable () -> Bool
    public var csrfToken:         @Sendable () -> String?

    // MARK: Entity CRUD (Data in, Data out; use the generic extensions for Codable types)
    public var get:     @Sendable (_ entity: EntityType, _ id: String, _ query: [String: String]) async throws -> Data
    public var create:  @Sendable (_ entity: EntityType, _ body: Data) async throws -> Data
    public var update:  @Sendable (_ entity: EntityType, _ id: String, _ body: Data) async throws -> Data
    public var delete:  @Sendable (_ entity: EntityType, _ id: String) async throws -> Void

    // MARK: Other
    public var view:    @Sendable (_ path: String, _ query: [String: String]) async throws -> Data
    public var request: @Sendable (_ path: String, _ method: String, _ query: [String: String], _ body: Data?) async throws -> Data

    public init(
        login: @escaping @Sendable (String, String) async throws -> LoginResponse,
        logout: @escaping @Sendable () async throws -> Void,
        refreshCSRFToken: @escaping @Sendable () async throws -> String,
        setAuthentication: @escaping @Sendable (Authentication) -> Void,
        isLoggedIn: @escaping @Sendable () -> Bool,
        csrfToken: @escaping @Sendable () -> String?,
        get: @escaping @Sendable (EntityType, String, [String: String]) async throws -> Data,
        create: @escaping @Sendable (EntityType, Data) async throws -> Data,
        update: @escaping @Sendable (EntityType, String, Data) async throws -> Data,
        delete: @escaping @Sendable (EntityType, String) async throws -> Void,
        view: @escaping @Sendable (String, [String: String]) async throws -> Data,
        request: @escaping @Sendable (String, String, [String: String], Data?) async throws -> Data
    ) {
        self.login = login
        self.logout = logout
        self.refreshCSRFToken = refreshCSRFToken
        self.setAuthentication = setAuthentication
        self.isLoggedIn = isLoggedIn
        self.csrfToken = csrfToken
        self.get = get
        self.create = create
        self.update = update
        self.delete = delete
        self.view = view
        self.request = request
    }
}

// MARK: - Codable convenience

public extension DrupalClient {

    /// Encode `body` as JSON and POST it to `/entity/{type}?_format=json`.
    @discardableResult
    func create<T: Encodable>(_ entity: EntityType, body: T) async throws -> Data {
        try await create(entity, JSONEncoder().encode(body))
    }

    /// Encode `body` as JSON and PATCH it to `/{entity}/{id}?_format=json`.
    @discardableResult
    func update<T: Encodable>(_ entity: EntityType, id: String, body: T) async throws -> Data {
        try await update(entity, id, JSONEncoder().encode(body))
    }

    /// GET `path` and decode the JSON response into `T`.
    func get<T: Decodable>(_ type: T.Type, path: String, query: [String: String] = [:]) async throws -> T {
        let data = try await request(path, "GET", query, nil)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw DrupalError.decoding(error)
        }
    }

    /// GET an entity and decode the JSON response into `T`.
    func get<T: Decodable>(_ type: T.Type, entity: EntityType, id: String, query: [String: String] = [:]) async throws -> T {
        let data = try await get(entity, id, query)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw DrupalError.decoding(error)
        }
    }
}
