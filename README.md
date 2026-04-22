
![Waterwheel - Drupal SDK](https://raw.githubusercontent.com/acquia/waterwheel-swift/assets/waterwheel.png)

[![CocoaPods](https://img.shields.io/cocoapods/v/waterwheel.svg?maxAge=43000)]()
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](#swift-package-manager)
![Swift version](https://img.shields.io/badge/swift-5.9-orange.svg)
[![Drupal version](https://img.shields.io/badge/Drupal-10%20%7C%2011-blue.svg)]()
[![Platforms](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-green.svg)](#)

#### Waterwheel Swift SDK for `Drupal`

Waterwheel makes using Drupal as a backend for iOS, macOS, tvOS, and watchOS
apps enjoyable. It wraps the most common operations of Drupal's
[RESTful Web Services API](https://www.drupal.org/docs/drupal-apis/restful-web-services-api/restful-web-services-api-overview)
(Drupal 10 / 11) behind a small, modern Swift surface.

-------
<p align="center">
    <a href="#features-in-5x">Features</a> &bull;
    <a href="#requirements">Requirements</a> &bull;
    <a href="#installation">Installation</a> &bull;
    <a href="#configuration">Configuration</a> &bull;
    <a href="#usage">Usage</a> &bull;
    <a href="#migrating-from-4x">Migrating from 4.x</a>
</p>

--------

## Features in 5.x
- [x] Drupal 10 / 11 core REST module
- [x] `async` / `await` API, built on `URLSession`
- [x] **No third-party dependencies** (Alamofire, SwiftyJSON, ObjectMapper, SwiftyUserDefaults all gone)
- [x] Swift Package Manager support
- [x] Cookie session authentication with automatic CSRF token management
- [x] HTTP Basic auth and OAuth 2 Bearer token auth
- [x] Entity CRUD (node, comment, user, taxonomy term, media, file — plus anything custom)
- [x] Views REST export helper
- [x] iOS UI helpers: `waterwheelAuthButton`, `waterwheelLoginViewController`, `waterwheelViewTableViewController`

## Requirements
- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+
- Swift 5.9 / Xcode 15+
- Drupal 10 or 11 with the core `rest` module enabled and a user role permitted to use the `application/json` format

## Installation

#### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/kylebrowning/waterwheel-swift.git", from: "5.0.0")
]
```

or from Xcode: **File → Add Package Dependencies…** and paste the repo URL.

#### CocoaPods

```ruby
pod 'waterwheel', '~> 5.0'
```

## Configuration

```swift
import Waterwheel

Waterwheel.shared.configure(baseURL: URL(string: "https://example.com")!)
```

If your Drupal site allows anonymous access to the resources you need, that's
all you have to do. Otherwise pick an authentication mode.

### Authentication

#### Cookie session (default)

```swift
let session = try await Waterwheel.shared.login(
    username: "admin",
    password: "hunter2"
)
print("Logged in as", session.currentUser?.name ?? "unknown")
```

Waterwheel stores the session cookie in `HTTPCookieStorage.shared` and the
CSRF / logout tokens in `UserDefaults`, so state survives app restarts.

#### HTTP Basic

```swift
Waterwheel.shared.setAuthentication(.basic(username: "admin", password: "hunter2"))
```

#### OAuth 2 Bearer token

```swift
Waterwheel.shared.setAuthentication(.bearer(token: accessToken))
```

### CSRF tokens

For unsafe (POST / PATCH / DELETE) requests using a cookie session, Drupal
requires an `X-CSRF-Token` header. Waterwheel fetches it automatically from
`/session/token` the first time it's needed, but you can force a refresh:

```swift
try await Waterwheel.shared.refreshCSRFToken()
```

## Usage

### Read a node

```swift
let data = try await Waterwheel.shared.get(.node, id: "36")
```

Or decode straight into your own type:

```swift
struct NodeResponse: Decodable { let nid: [[String: Int]] }
let node: NodeResponse = try await Waterwheel.shared.requestDecoded(
    NodeResponse.self,
    path: "node/36",
    query: ["_format": "json"]
)
```

### Create a node

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
let created = try await Waterwheel.shared.create(.node, body: payload)
```

### Update / delete a node

```swift
try await Waterwheel.shared.update(.node, id: "36", body: payload)
try await Waterwheel.shared.delete(.node, id: "36")
```

### Any entity

```swift
try await Waterwheel.shared.get(.taxonomyTerm, id: "7")
try await Waterwheel.shared.create(.comment, body: myComment)
```

### Views REST export

```swift
let data = try await Waterwheel.shared.view(at: "api/latest-articles")
```

### Logout

```swift
try await Waterwheel.shared.logout()
```

## iOS UI helpers

Everything under `Sources/iOS` is gated by `#if os(iOS)`.

```swift
let loginButton = waterwheelAuthButton()
loginButton.didPressLogin = { self.present(myLoginVC, animated: true) }
loginButton.didPressLogout = { success, error in print("logged out:", success) }
view.addSubview(loginButton)
```

## Migrating from 4.x

- `waterwheel.setDrupalURL("...")` → `Waterwheel.shared.configure(baseURL: URL(string: "...")!)`
- `waterwheel.login(username:password:) { ... }` → `try await Waterwheel.shared.login(username:password:)`
- `waterwheel.nodeGet(nodeId:)` → `try await Waterwheel.shared.get(.node, id:)`
- `waterwheel.entityPost(entityType:params:)` → `try await Waterwheel.shared.create(.node, body:)`
- `waterwheel.entityPatch(entityType:entityId:params:)` → `try await Waterwheel.shared.update(.node, id:, body:)`
- `waterwheel.entityDelete(...)` → `try await Waterwheel.shared.delete(.node, id:)`
- `DataResponse<Any>` / `SwiftyJSON.JSON` return values are gone — use `Codable`, `JSONDecoder`, or raw `Data`.
- Notification names moved to `Notification.Name.waterwheelDidLogin` / `.waterwheelDidFinishRequest` etc.

A deprecated `WaterwheelCompat` namespace provides a thin closure-based bridge
for the most common pre-5.x calls.

## Drupal compatibility

| waterwheel version | Drupal version | Notes |
| ------------------ | -------------- | ----- |
| 5.x (this branch)  | Drupal 10, 11  | Swift 5.9, async/await, zero deps |
| 4.x                | Drupal 8       | Swift 3, Alamofire 4, SwiftyJSON |
| 3.x                | Drupal 8       | Objective-C |
| 2.x                | Drupal 6–7     | Obj-C, requires the `services` module |

## Communication

- Found a bug? Open an issue.
- Want a feature? Open an issue or a pull request.

<a href="#">Back to Top</a>
