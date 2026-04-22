//
//  AppDelegate.swift
//  DrupalIOSSDKDemo-iOS
//

import UIKit
import DrupalIOSSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Point the SDK at your Drupal site before issuing any requests.
        Drupal.shared.configure(baseURL: URL(string: "https://example.com")!)

        // Example: fetch node 1 on launch.
        Task {
            do {
                let data = try await Drupal.shared.get(.node, id: "1")
                if let body = String(data: data, encoding: .utf8) {
                    print("node 1 payload:\n\(body)")
                }
            } catch {
                print("failed to fetch node 1:", error.localizedDescription)
            }
        }
        return true
    }
}
