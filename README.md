# Drupal iOS SDK

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](#swift-package-manager)
![Swift version](https://img.shields.io/badge/swift-5.9-orange.svg)
[![Drupal version](https://img.shields.io/badge/Drupal-10%20%7C%2011-blue.svg)]()
[![Platforms](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-green.svg)](#)

A Swift SDK for building iOS, macOS, tvOS, and watchOS apps on top of Drupal.
It wraps the most common operations of Drupal's
[RESTful Web Services API](https://www.drupal.org/docs/drupal-apis/restful-web-services-api/restful-web-services-api-overview)
(Drupal 10 / 11) behind a small, modern Swift surface.

> **History:** 5.x is a ground-up rewrite of the former
> [waterwheel-swift](https://github.com/kylebrowning/waterwheel-swift) SDK.
> The Swift module has been renamed `DrupalIOSSDK` and the type names no longer
> carry the `waterwheel` prefix. See [Migrating from 4.x](#migrating-from-4x) below.

-------
<p align="center">
    <a href="#features">Features</a> &bull;
    <a href="#requirements">Requirements</a> &bull;
    <a href="#installation">Installation</a> &bull;
    <a href="#configuration">Configuration</a> &bull;
    <a href="#usage">Usage</a> &bull;
    <a href="#ui-helpers">UI helpers</a> &bull;
    <a href="#migrating-from-4x">Migrating from 4.x</a>
</p>

--------

## Features

- [x] Drupal 10 / 11 core REST module
- [x] `async` / `await` API, built on `URLSession`
- [x] **No third-party dependencies** (Alamofire, SwiftyJSON, ObjectMapper, SwiftyUserDefaults all gone)
- [x] Swift Package Manager **and** CocoaPods support
- [x] Cookie session authentication with automatic CSRF token management
- [x] HTTP Basic auth and OAuth 2 Bearer token auth
- [x] Entity CRUD (node, comment, user, taxonomy term, media, file — plus anything custom)
- [x] Views REST export helper
- [x] Separate `DrupalIOSSDKUI` module: `DrupalAuthButton`, `DrupalLoginViewController`, `DrupalViewTableViewController`

## Package layout

| Product           | Module            | Platforms                        | Purpose                              |
| ----------------- | ----------------- | -------------------------------- | ------------------------------------ |
| `DrupalIOSSDK`    | `DrupalIOSSDK`    | iOS, macOS, tvOS, watchOS        | Core networking + auth (Foundation)  |
| `DrupalIOSSDKUI`  | `DrupalIOSSDKUI`  | iOS                              | UIKit helpers (depends on core)      |

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
.product(name: "DrupalIOSSDK",   package: "drupal-ios-sdk"),   // networking
.product(name: "DrupalIOSSDKUI", package: "drupal-ios-sdk"),   // optional, iOS-only UIKit helpers
```

Or from Xcode: **File → Add Package Dependencies…** and paste the repo URL,
then check the products you want to link.

### CocoaPods

```ruby
pod 'DrupalIOSSDK'               # core (default subspec)
pod 'DrupalIOSSDK/UI'            # optional, adds the UIKit helpers
```

## Configuration

```swift
import DrupalIOSSDK

Drupal.shared.configure(baseURL: URL(string: "https://example.com")!)
```

If your Drupal site allows anonymous access to the resources you need, that's
all you have to do. Otherwise pick an authentication mode.

### Authentication

#### Cookie session (default)

```swift
let session = try await Drupal.shared.login(
    username: "admin",
    password: "hunter2"
)
print("logged in as", session.currentUser?.name ?? "unknown")
```

The session cookie is kept in `HTTPCookieStorage.shared` and the CSRF / logout
tokens are stored in `UserDefaults`, so state survives app restarts.

#### HTTP Basic

```swift
Drupal.shared.setAuthentication(.basic(username: "admin", password: "hunter2"))
```

#### OAuth 2 Bearer token

```swift
Drupal.shared.setAuthentication(.bearer(token: accessToken))
```

### CSRF tokens

For unsafe (POST / PATCH / DELETE) requests using a cookie session, Drupal
requires an `X-CSRF-Token` header. The SDK fetches it automatically from
`/session/token` the first time it's needed. Force a refresh with:

```swift
try await Drupal.shared.refreshCSRFToken()
```

## Usage

### Read a node

```swift
let data = try await Drupal.shared.get(.node, id: "36")
```

Or decode straight into your own type:

```swift
struct NodeResponse: Decodable { let nid: [[String: Int]] }
let node: NodeResponse = try await Drupal.shared.requestDecoded(
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
let created = try await Drupal.shared.create(.node, body: payload)
```

### Update / delete a node

```swift
try await Drupal.shared.update(.node, id: "36", body: payload)
try await Drupal.shared.delete(.node, id: "36")
```

### Any entity

```swift
try await Drupal.shared.get(.taxonomyTerm, id: "7")
try await Drupal.shared.create(.comment, body: myComment)
```

### Views REST export

```swift
let data = try await Drupal.shared.view(at: "api/latest-articles")
```

### Logout

```swift
try await Drupal.shared.logout()
```

## UI helpers

`DrupalIOSSDKUI` (iOS only) ships UIKit classes that stay in sync with the
SDK's auth state:

```swift
import DrupalIOSSDKUI

let loginButton = DrupalAuthButton()
loginButton.didPressLogin  = { self.present(myLoginVC, animated: true) }
loginButton.didPressLogout = { success, error in print("logged out:", success) }
view.addSubview(loginButton)
```

See `DrupalIOSSDKDemo/` for a runnable sample app that links the local SPM
package and uses `DrupalAuthButton`, `DrupalLoginViewController`, and
`DrupalViewTableViewController`.

## Running the demo

1. Open `DrupalIOSSDKDemo/DrupalIOSSDKDemo-iOS/DrupalIOSSDKDemo-iOS.xcworkspace`
   in Xcode 15+. The project declares a local Swift Package reference to the
   repo root, so no Carthage/CocoaPods step is needed.
2. Edit `DrupalIOSSDKDemo-iOS/AppDelegate.swift` and point
   `Drupal.shared.configure(baseURL:)` at your Drupal site.
3. Build and run on an iOS 15+ device or simulator.

## Migrating from 4.x

- **Module & types renamed.** `import waterwheel` → `import DrupalIOSSDK`; the
  singleton is now `Drupal.shared`. UI classes are now in a separate product,
  `DrupalIOSSDKUI`: `waterwheelAuthButton` → `DrupalAuthButton`,
  `waterwheelLoginViewController` → `DrupalLoginViewController`,
  `waterwheelViewTableViewController` → `DrupalViewTableViewController`.
- `waterwheel.setDrupalURL("...")` → `Drupal.shared.configure(baseURL: URL(string: "...")!)`
- `waterwheel.login(username:password:) { ... }` → `try await Drupal.shared.login(username:password:)`
- `waterwheel.nodeGet(nodeId:)` → `try await Drupal.shared.get(.node, id:)`
- `waterwheel.entityPost(entityType:params:)` → `try await Drupal.shared.create(.node, body:)`
- `waterwheel.entityPatch(entityType:entityId:params:)` → `try await Drupal.shared.update(.node, id:, body:)`
- `waterwheel.entityDelete(...)` → `try await Drupal.shared.delete(.node, id:)`
- Notification names moved to `Notification.Name.drupalDidLogin`,
  `.drupalDidLogout`, `.drupalDidStartRequest`, `.drupalDidFinishRequest`.
- `DataResponse<Any>` / `SwiftyJSON.JSON` return types are gone — use
  `Codable`, `JSONDecoder`, or raw `Data`.

## Drupal compatibility

| SDK version | Drupal version | Notes |
| ----------- | -------------- | ----- |
| 5.x         | Drupal 10, 11  | Swift 5.9, async/await, zero deps, module renamed to `DrupalIOSSDK` |
| 4.x         | Drupal 8       | Swift 3, Alamofire 4, SwiftyJSON, module `waterwheel` |
| 3.x         | Drupal 8       | Objective-C |
| 2.x         | Drupal 6–7     | Obj-C, requires the `services` module |

## Communication

- Found a bug? Open an issue.
- Want a feature? Open an issue or a pull request.
