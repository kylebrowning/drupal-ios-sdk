# Drupal iOS SDK

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](#swift-package-manager)
![Swift version](https://img.shields.io/badge/swift-5.9-orange.svg)
[![Drupal version](https://img.shields.io/badge/Drupal-10%20%7C%2011-blue.svg)]()
[![Platforms](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-green.svg)](#)

A Swift SDK for building iOS, macOS, tvOS, and watchOS apps on top of Drupal.
It wraps the most common operations of Drupal's
[RESTful Web Services API](https://www.drupal.org/docs/drupal-apis/restful-web-services-api/restful-web-services-api-overview)
(Drupal 10 / 11) behind a small, modern Swift surface built on `async` /
`await` and closure-based dependency injection — no singleton, no protocols.

> **History:** 5.x is a ground-up rewrite of the former
> [waterwheel-swift](https://github.com/kylebrowning/waterwheel-swift) SDK.
> The Swift module has been renamed `DrupalIOSSDK`, the main value type is
> now `DrupalClient`, and UI has moved to SwiftUI in a separate product
> `DrupalIOSSDKUI`. See [Migrating from 4.x](#migrating-from-4x).

-------
<p align="center">
    <a href="#features">Features</a> &bull;
    <a href="#requirements">Requirements</a> &bull;
    <a href="#installation">Installation</a> &bull;
    <a href="#the-drupalclient-di-pattern">The <code>DrupalClient</code> DI pattern</a> &bull;
    <a href="#usage">Usage</a> &bull;
    <a href="#swiftui-helpers">SwiftUI helpers</a> &bull;
    <a href="#migrating-from-4x">Migrating from 4.x</a>
</p>

--------

## Features

- [x] Drupal 10 / 11 core REST module
- [x] `async` / `await` API built on `URLSession`
- [x] **Closure-based dependency injection** (no singleton, no protocols) — inspired by [Kyle Browning's *Dependency Injection in SwiftUI Without the Ceremony*](https://kylebrowning.com/posts/dependency-injection-in-swiftui/)
- [x] SwiftUI environment integration: `@Environment(\.drupal) var drupal`
- [x] **No third-party dependencies** — zero Alamofire, zero SwiftyJSON, zero ObjectMapper
- [x] Cookie session auth with automatic CSRF token management
- [x] HTTP Basic auth and OAuth 2 Bearer token auth
- [x] Entity CRUD (node, comment, user, taxonomy term, media, file — plus anything custom)
- [x] Views REST export helper
- [x] Separate SwiftUI helpers product: `DrupalAuthButton`, `DrupalLoginView`, `DrupalViewList`
- [x] Swift Package Manager **and** CocoaPods support

## Package layout

| Product           | Module            | Platforms                        | Purpose                              |
| ----------------- | ----------------- | -------------------------------- | ------------------------------------ |
| `DrupalIOSSDK`    | `DrupalIOSSDK`    | iOS, macOS, tvOS, watchOS        | Closure-based `DrupalClient` + auth  |
| `DrupalIOSSDKUI`  | `DrupalIOSSDKUI`  | iOS, macOS, tvOS, watchOS        | SwiftUI helpers (depends on core)    |

## Requirements

- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+
- Swift 5.9 / Xcode 15+
- Drupal 10 or 11 with the core `rest` module enabled and a user role permitted to use the `application/json` format

## Installation

### Swift Package Manager

Add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/kylebrowning/drupal-ios-sdk.git", from: "5.0.0")
]
```

Then opt into the products you need:

```swift
.product(name: "DrupalIOSSDK",   package: "drupal-ios-sdk"),   // networking / DI
.product(name: "DrupalIOSSDKUI", package: "drupal-ios-sdk"),   // optional SwiftUI helpers
```

Or from Xcode: **File → Add Package Dependencies…** and paste the repo URL.

### CocoaPods

```ruby
pod 'DrupalIOSSDK'               # core (default subspec)
pod 'DrupalIOSSDK/UI'            # optional SwiftUI helpers
```

## The `DrupalClient` DI pattern

`DrupalIOSSDK` exposes its entire API surface as a single value-type `struct`
whose stored properties are `@Sendable` async closures. The struct itself *is*
the protocol — different factory functions produce different instances:

```swift
public struct DrupalClient: Sendable {
    public var login:   @Sendable (String, String) async throws -> LoginResponse
    public var logout:  @Sendable () async throws -> Void
    public var get:     @Sendable (EntityType, String, [String: String]) async throws -> Data
    public var create:  @Sendable (EntityType, Data) async throws -> Data
    public var update:  @Sendable (EntityType, String, Data) async throws -> Data
    public var delete:  @Sendable (EntityType, String) async throws -> Void
    public var view:    @Sendable (String, [String: String]) async throws -> Data
    public var request: @Sendable (String, String, [String: String], Data?) async throws -> Data
    // …plus isLoggedIn, csrfToken, setAuthentication, refreshCSRFToken
}
```

The SDK ships three factories:

| Factory              | What it does                                                              |
| -------------------- | ------------------------------------------------------------------------- |
| `.live(baseURL:)`    | Real `URLSession`-backed client. Use this in production.                  |
| `.mock(initiallyLoggedIn:)` | In-memory fake for SwiftUI previews and tests.                      |
| `.unimplemented`     | Every closure throws `DrupalError.unimplemented` — the Environment default so missing DI fails loudly. |

Injection uses SwiftUI's environment system:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.drupal, .live(baseURL: URL(string: "https://example.com")!))
        }
    }
}

struct ContentView: View {
    @Environment(\.drupal) private var drupal
    var body: some View { /* use drupal.login, drupal.get, … */ }
}
```

In tests or Xcode Previews, swap in `.mock()` or a custom `DrupalClient`
built from your own closures:

```swift
#Preview {
    ContentView()
        .environment(\.drupal, .mock(initiallyLoggedIn: true))
}

let fake = DrupalClient(
    login: { _, _ in LoginResponse(csrfToken: "t", logoutToken: "u", currentUser: nil) },
    // …other closures…
)
```

## Usage

All snippets assume `@Environment(\.drupal) private var drupal` (or a client
passed in via initializer).

### Authentication

```swift
// Cookie session
let session = try await drupal.login("admin", "hunter2")

// HTTP Basic
drupal.setAuthentication(.basic(username: "admin", password: "hunter2"))

// OAuth 2 bearer
drupal.setAuthentication(.bearer(token: accessToken))

// Logout
try await drupal.logout()
```

CSRF tokens are fetched automatically from `/session/token` the first time an
unsafe method is issued on a cookie-authenticated session. Force a refresh with
`try await drupal.refreshCSRFToken()`.

### Reading entities

```swift
let data: Data = try await drupal.get(.node, "36", [:])          // raw

struct MyNode: Decodable { /* … */ }
let node: MyNode = try await drupal.get(MyNode.self, entity: .node, id: "36")
```

### Creating / updating entities

```swift
struct NewArticle: Encodable {
    let type: [[String: String]]
    let title: [[String: String]]
    let body: [[String: String]]
}
let payload = NewArticle(
    type:  [["target_id": "article"]],
    title: [["value": "Hello World"]],
    body:  [["value": "How are you?"]]
)
try await drupal.create(.node, body: payload)
try await drupal.update(.node, id: "36", body: payload)
try await drupal.delete(.node, "36")
```

### Views REST export

```swift
let data = try await drupal.view("api/latest-articles", [:])
```

### Arbitrary requests

```swift
let data = try await drupal.request("some/custom/path", "GET", ["_format": "json"], nil)
let decoded: MyType = try await drupal.get(MyType.self, path: "some/custom/path")
```

## SwiftUI helpers

`DrupalIOSSDKUI` ships three SwiftUI views, each backed by
`@Environment(\.drupal)`:

### `DrupalAuthButton`

A button that reads `drupal.isLoggedIn()` on appear and observes
`.drupalDidLogin` / `.drupalDidLogout` notifications to stay in sync. Triggers
logout automatically when tapped while authenticated.

```swift
DrupalAuthButton(
    onLoginTap: { isPresentingLogin = true },
    onLogout:   { result in print("logged out:", result) }
)
```

### `DrupalLoginView`

A ready-to-use username/password form that calls `drupal.login` and surfaces
errors inline.

```swift
DrupalLoginView(
    prefilledUsername: "demo",
    onSuccess: { _ in dismiss() },
    onCancel:  { dismiss() }
)
```

### `DrupalViewList<Row, RowView>`

Fetches a Drupal View's REST export and renders rows with a SwiftUI builder.

```swift
struct Article: Decodable, Identifiable {
    let id: String
    let title: String?
}

DrupalViewList<Article, AnyView>(viewPath: "frontpage") { article in
    AnyView(Text(article.title ?? "Untitled"))
}
```

## Running the demo

1. Open `DrupalIOSSDKDemo/DrupalIOSSDKDemo-iOS/DrupalIOSSDKDemo-iOS.xcworkspace`
   in Xcode 15+. The project declares a local Swift Package reference to the
   repo root, so no Carthage or CocoaPods step is required.
2. Edit `DrupalIOSSDKDemo-iOS/DrupalIOSSDKDemoApp.swift` and point
   `.live(baseURL:)` at your Drupal site.
3. Build and run on an iOS 15+ device or simulator.

## Migrating from 4.x

- **Module & types renamed.** `import waterwheel` → `import DrupalIOSSDK`.
  Instead of a `Waterwheel.shared` singleton, you now construct (or inject)
  a `DrupalClient`.
- **Inject; don't reach for shared state.**
  `waterwheel.setDrupalURL("...")` → `.environment(\.drupal, .live(baseURL: URL(string: "...")!))`
  at your SwiftUI app root.
- `waterwheel.login(username:password:) { ... }` → `try await drupal.login(username, password)`
- `waterwheel.nodeGet(nodeId:)` → `try await drupal.get(.node, id, [:])`
- `waterwheel.entityPost(entityType:params:)` → `try await drupal.create(.node, body: payload)`
- `waterwheel.entityPatch(entityType:entityId:params:)` → `try await drupal.update(.node, id: id, body: payload)`
- `waterwheel.entityDelete(...)` → `try await drupal.delete(.node, id)`
- **UI moved to SwiftUI.** `waterwheelAuthButton`, `waterwheelLoginViewController`,
  and `waterwheelViewTableViewController` (UIKit) were replaced by
  `DrupalAuthButton`, `DrupalLoginView`, and `DrupalViewList` (SwiftUI).
- Notification names moved to `.drupalDidLogin`, `.drupalDidLogout`,
  `.drupalDidStartRequest`, `.drupalDidFinishRequest`.
- `DataResponse<Any>` / `SwiftyJSON.JSON` return types are gone — use
  `Codable`, `JSONDecoder`, or raw `Data`.

## Drupal compatibility

| SDK version | Drupal version | Notes |
| ----------- | -------------- | ----- |
| 5.x         | Drupal 10, 11  | Swift 5.9, async/await, SwiftUI, closure-based DI, zero deps |
| 4.x         | Drupal 8       | Swift 3, Alamofire 4, SwiftyJSON, module `waterwheel` |
| 3.x         | Drupal 8       | Objective-C |
| 2.x         | Drupal 6–7     | Obj-C, requires the `services` module |

## Communication

- Found a bug? Open an issue.
- Want a feature? Open an issue or a pull request.
