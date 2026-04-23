#Change Log
All notable changes to this project will be documented in this file. starting with version 4.2.5
---

## [5.0.0] (2026-04-22)

#### Drupal 10 / 11 support — major rewrite + rebrand + SwiftUI / DI

The project is renamed from **Waterwheel** to **Drupal iOS SDK**. The Swift
module is now `DrupalIOSSDK`, the main API is a closure-based `DrupalClient`
value type injected via SwiftUI's `@Environment`, and UI helpers live in a
separate SwiftUI-based product, `DrupalIOSSDKUI`.

**Added**
* Targets the Drupal 10 / 11 core RESTful Web Services API.
* **`DrupalClient` value type** — a `Sendable` struct whose stored properties
  are `@Sendable` async closures. Inspired by Kyle Browning's
  [*Dependency Injection in SwiftUI Without the Ceremony*](https://kylebrowning.com/posts/dependency-injection-in-swiftui/).
  Ships three factories:
    - `.live(baseURL:authentication:urlSession:userDefaults:)` — real client
    - `.mock(initiallyLoggedIn:)` — preview/test double
    - `.unimplemented` — loud-failure default surfaced via the environment
* **SwiftUI Environment integration** — `EnvironmentValues.drupal`; inject with
  `.environment(\.drupal, .live(baseURL:))`; read with `@Environment(\.drupal)`.
* Full `async` / `await` API on `DrupalClient` with typed `EntityType`,
  `Authentication`, `DrupalError`, and `LoginResponse` value types.
* `Codable` convenience extensions on `DrupalClient`:
  `create<T: Encodable>(_:body:)`, `update<T: Encodable>(_:id:body:)`,
  `get<T: Decodable>(_:path:query:)`, `get<T: Decodable>(_:entity:id:query:)`.
* Automatic CSRF token refresh from `/session/token` with `X-CSRF-Token` on
  unsafe requests.
* Swift Package Manager support via `Package.swift` shipping two products:
  `DrupalIOSSDK` (core, all Apple platforms) and `DrupalIOSSDKUI` (SwiftUI
  helpers on all Apple platforms).
* SwiftUI helper views in `DrupalIOSSDKUI`:
    - `DrupalAuthButton` — observes `.drupalDidLogin` / `.drupalDidLogout`.
    - `DrupalLoginView` — username/password form driving `drupal.login`.
    - `DrupalViewList<Row, RowView>` — fetches a Drupal View's REST export
      and renders with a `@ViewBuilder` row builder.
* `Notification.Name` extensions: `.drupalDidLogin`, `.drupalDidLogout`,
  `.drupalDidStartRequest`, `.drupalDidFinishRequest`.
* A SwiftUI demo app under `DrupalIOSSDKDemo/` that links the local SPM
  package and demonstrates `.live` injection at the app root, login via
  `DrupalLoginView`, browsing via `DrupalViewList`, and raw-node fetches
  via `drupal.get(.node, …)`.

**Changed**
* Module renamed: `import waterwheel` → `import DrupalIOSSDK`
  (plus `import DrupalIOSSDKUI` for the SwiftUI helpers).
* **Singleton `Waterwheel.shared` removed.** Construct a `DrupalClient` with
  `.live(baseURL:)` and inject it via SwiftUI Environment (or pass explicitly
  into initializers).
* UIKit helpers replaced by SwiftUI equivalents (see `DrupalIOSSDKUI` above).
* Source tree reorganized under `Sources/DrupalIOSSDK/` and
  `Sources/DrupalIOSSDKUI/`; multi-file core split into `DrupalTypes.swift`,
  `DrupalClient.swift`, `DrupalClient+Live.swift`,
  `DrupalClient+Unimplemented.swift`, and `DrupalClient+Environment.swift`.
* Minimum platforms raised to iOS 15 / macOS 12 / tvOS 15 / watchOS 8
  (needed for `URLSession`'s async/await API and SwiftUI's environment).
* Swift language version is now 5.9.
* Login endpoint uses `/user/login?_format=json` and stores `csrf_token` /
  `logout_token` from the response.
* Podspec renamed `waterwheel.podspec` → `DrupalIOSSDK.podspec`, with `Core`
  and `UI` subspecs.
* Demo app rewritten in SwiftUI (`@main struct DrupalIOSSDKDemoApp: App`,
  `ContentView`, `FrontpageView`, `NodeDetailView`); the UIKit storyboards,
  `AppDelegate.swift`, and view-controller classes are removed.

**Removed**
* `Waterwheel.shared` singleton.
* UIKit UI helpers: `DrupalAuthButton` (UIKit), `DrupalLoginViewController`,
  `DrupalViewTableViewController`, and the `UIView` layout extension.
  SwiftUI equivalents replace them.
* Alamofire dependency — replaced with `URLSession`.
* SwiftyJSON dependency — replaced with `Codable` / `JSONDecoder`.
* SwiftyUserDefaults dependency — replaced with `UserDefaults`.
* ObjectMapper dependency — replaced with `Decodable`.
* Carthage wiring (Cartfile, submodules, `Carthage/Checkouts/*`) deleted.
* The legacy multi-platform framework Xcode project (`waterwheel.xcodeproj`)
  is removed. Open `Package.swift` directly in Xcode (or use `swift build`);
  CocoaPods installs continue to work.
* Demo storyboards (`Main.storyboard`, `LaunchScreen.storyboard`) and
  `AppDelegate.swift` replaced by the SwiftUI `App` entry point.


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
