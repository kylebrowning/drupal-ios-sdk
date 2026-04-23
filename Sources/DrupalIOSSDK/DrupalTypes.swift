//
//  DrupalTypes.swift
//  DrupalIOSSDK — Public types shared by the client and its implementations.
//
//  Docs: https://www.drupal.org/docs/drupal-apis/restful-web-services-api/restful-web-services-api-overview
//

import Foundation

// MARK: - Entities

/// Content entity types exposed by the Drupal core REST module. Extend as needed.
public enum EntityType: String, Sendable, Hashable {
    case node
    case comment
    case user
    case taxonomyTerm = "taxonomy_term"
    case mediaItem = "media"
    case file

    /// Canonical URL fragment for the entity type. Most entities have a
    /// canonical URL of `/{type}/{id}`; those that do not fall back to
    /// `/entity/{type}/{id}`.
    public var canonicalPath: String {
        switch self {
        case .node, .user, .file, .mediaItem:
            return rawValue
        case .comment, .taxonomyTerm:
            return "entity/\(rawValue)"
        }
    }
}

// MARK: - Authentication

/// Authentication modes supported by the core REST module.
public enum Authentication: Sendable, Equatable {
    case none
    case cookie
    case basic(username: String, password: String)
    case bearer(token: String)
}

// MARK: - Errors

public enum DrupalError: Error, LocalizedError {
    case missingBaseURL
    case invalidURL(String)
    case invalidResponse
    case http(status: Int, body: Data?)
    case decoding(Error)
    case missingCSRFToken
    case unimplemented(String)

    public var errorDescription: String? {
        switch self {
        case .missingBaseURL:
            return "DrupalIOSSDK: base URL has not been set."
        case .invalidURL(let s):
            return "DrupalIOSSDK: invalid URL \(s)."
        case .invalidResponse:
            return "DrupalIOSSDK: the server returned an invalid response."
        case .http(let status, _):
            return "DrupalIOSSDK: HTTP \(status)."
        case .decoding(let e):
            return "DrupalIOSSDK: failed to decode response (\(e.localizedDescription))."
        case .missingCSRFToken:
            return "DrupalIOSSDK: CSRF token is required for this request but is not available."
        case .unimplemented(let name):
            return "DrupalIOSSDK: \(name) was called on an `.unimplemented` client. Inject a real client via `.environment(\\.drupal, .live(baseURL:))`."
        }
    }
}

// MARK: - Login response

public struct LoginResponse: Decodable, Sendable, Equatable {
    public let csrfToken: String?
    public let logoutToken: String?
    public let currentUser: CurrentUser?

    enum CodingKeys: String, CodingKey {
        case csrfToken = "csrf_token"
        case logoutToken = "logout_token"
        case currentUser = "current_user"
    }

    public struct CurrentUser: Decodable, Sendable, Equatable {
        public let uid: String?
        public let name: String?
        public let roles: [String]?
    }
}

// MARK: - Notifications

/// Notification names posted on `NotificationCenter.default` around request
/// lifecycle events. Useful for driving UI (e.g. auth buttons).
public extension Notification.Name {
    static let drupalDidLogin         = Notification.Name("drupalDidLogin")
    static let drupalDidLogout        = Notification.Name("drupalDidLogout")
    static let drupalDidStartRequest  = Notification.Name("drupalDidStartRequest")
    static let drupalDidFinishRequest = Notification.Name("drupalDidFinishRequest")
}
