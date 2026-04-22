#Change Log
All notable changes to this project will be documented in this file. starting with version 4.2.5
---

## [5.0.0] (2026-04-22)

#### Drupal 10 / 11 support — major rewrite

**Added**
* Targets the Drupal 10 / 11 core RESTful Web Services API.
* Full `async` / `await` API surface on `Waterwheel.shared`.
* Swift Package Manager support (`Package.swift`).
* Typed `EntityType` enum covering `node`, `comment`, `user`, `taxonomy_term`, `media`, and `file`.
* `Authentication` enum with `.cookie`, `.basic(...)`, and `.bearer(...)` modes.
* Automatic CSRF token refresh from `/session/token` with `X-CSRF-Token` header on unsafe requests.
* `requestDecoded(_:path:method:query:body:)` generic helper for `Decodable` responses.
* `Notification.Name` extensions for request lifecycle notifications.
* Deprecated `WaterwheelCompat` namespace providing a closure-based bridge for 4.x callers.

**Changed**
* Minimum platforms raised to iOS 15 / macOS 12 / tvOS 15 / watchOS 8 (needed for `URLSession`'s async/await API).
* Swift language version is now 5.9.
* iOS UI helpers (`waterwheelAuthButton`, `waterwheelLoginViewController`,
  `waterwheelViewTableViewController`) rebuilt on top of the async core and
  guarded with `#if os(iOS)`.
* Login endpoint uses `/user/login?_format=json` and stores `csrf_token` /
  `logout_token` from the response.

**Removed**
* Alamofire dependency — replaced with `URLSession`.
* SwiftyJSON dependency — replaced with `Codable` / `JSONDecoder`.
* SwiftyUserDefaults dependency — replaced with `UserDefaults`.
* ObjectMapper dependency — replaced with `Decodable`.
* Carthage-specific wiring (Cartfile now empty); SwiftPM and CocoaPods are the
  supported installation paths.


## [4.3.2](https://github.com/Acquia/waterwheel.swift/releases/tag/4.3.2) (03/24/2017)
Released on Friday, March 24, 2017. All issues associated with this milestone can be found using this [filter](https://github.com/Acquia/waterwheel.swift/issues?q=milestone%3A4.3.2+is%3Aclosed).

#### Fixed
* Carthage support is broken.
 * Implemented by kylebrowning in [#153](https://github.com/acquia/waterwheel.swift/issues/153).
 

## [4.3.1](https://github.com/Acquia/waterwheel-swift/releases/tag/4.3.1) (09/30/2016)
Released on Friday, September 30, 2016. All issues associated with this milestone can be found using this [filter](https://github.com/Acquia/waterwheel-swift/issues?q=milestone%3A4.3.1+is%3Aclosed).

#### Updated
* Update Carthage to use regular SwiftyJSON
 * Implemented by kylebrowning in [#148](https://github.com/acquia/waterwheel-swift/issues/148).
 

## [4.3.0](https://github.com/Acquia/waterwheel-swift/releases/tag/4.3.0) (09/27/2016)
Released on Tuesday, September 27, 2016. All issues associated with this milestone can be found using this [filter](https://github.com/Acquia/waterwheel-swift/issues?q=milestone%3A4.3.0+is%3Aclosed).

#### Updated
* Update waterwheel demo to use waterwheel-swift.com
 * Implemented by kylebrowning in [#147](https://github.com/acquia/waterwheel-swift/issues/147).
* Support Swift 3.0
 * Implemented by kylebrowning in [#144](https://github.com/acquia/waterwheel-swift/issues/144).

#### Fixed
* Fixes Carthage support
 * Implemented by kylebrowning in [#146](https://github.com/acquia/waterwheel-swift/issues/146).
 

## [4.2.8](https://github.com/Acquia/waterwheel-swift/releases/tag/4.2.8) (08/26/2016)
Released on Friday, August 26, 2016. All issues associated with this milestone can be found using this [filter](https://github.com/Acquia/waterwheel-swift/issues?q=milestone%3A4.2.8+is%3Aclosed).

#### Added
* Provide ViewsTableViewController
 * Implemented by kylebrowning in [#141](https://github.com/acquia/waterwheel-swift/issues/141).

#### Fixed
* waterwheelLoginViewController has no cancel button/action
 * Implemented by kylebrowning in [#143](https://github.com/acquia/waterwheel-swift/issues/143).
 

## [4.2.7](https://github.com/Acquia/waterwheel-swift/releases/tag/4.2.7) (08/17/2016)
Released on Wednesday, August 17, 2016. All issues associated with this milestone can be found using this [filter](https://github.com/Acquia/waterwheel-swift/issues?q=milestone%3A4.2.7+is%3Aclosed).

#### Changed
* Rename ViewExtension because it can be confused with a Drupal View
 * Implemented by kylebrowning in [#140](https://github.com/acquia/waterwheel-swift/issues/140).
 

## [4.2.6](https://github.com/Acquia/waterwheel-swift/releases/tag/4.2.6) (08/16/2016)
Released on Tuesday, August 16, 2016. All issues associated with this milestone can be found using this [filter](https://github.com/Acquia/waterwheel-swift/issues?q=milestone%3A4.2.6+is%3Aclosed).

#### Updated
* 100% doc coverage for waterwheelAuthButton
 * Implemented by kylebrowning in [#138](https://github.com/acquia/waterwheel-swift/issues/138).

#### Changed
* Move Title color from Auth button out of setup
 * Implemented by kylebrowning in [#139](https://github.com/acquia/waterwheel-swift/issues/139).
 
 

## [4.2.5](https://github.com/Acquia/waterwheel-swift/releases/tag/4.2.5) (08/16/2016)
Released on Tuesday, August 16, 2016. All issues associated with this milestone can be found using this [filter](https://github.com/Acquia/waterwheel-swift/issues?q=milestone%3A4.2.5+is%3Aclosed).

#### Fixed
* properties on AuthButton are protected
 * Implemented by kylebrowning in [#137](https://github.com/acquia/waterwheel-swift/issues/137).
