//
//  LoginViewController.swift
//  DrupalIOSSDKDemo-iOS
//

import UIKit
import DrupalIOSSDKUI

class LoginViewController: UIViewController {

    @IBOutlet weak var authButton: DrupalAuthButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        let vc = DrupalLoginViewController()

        // Seed with demo credentials so you can try login/logout quickly.
        vc.usernameField.text = "demo"
        vc.passwordField.text = "demo"

        vc.loginRequestCompleted = { [weak self] success, error in
            if success {
                print("login succeeded")
                self?.dismiss(animated: true)
            } else if let error {
                print("login failed:", error.localizedDescription)
            }
        }

        vc.logoutRequestCompleted = { [weak self] success, error in
            if success {
                print("logout succeeded")
                self?.dismiss(animated: true)
            } else if let error {
                print("logout failed:", error.localizedDescription)
            }
        }

        vc.cancelButtonHit = { [weak self] in
            self?.dismiss(animated: true)
        }

        authButton.didPressLogin = { [weak self] in
            self?.present(vc, animated: true)
        }

        authButton.didPressLogout = { success, _ in
            print("logged out (via button):", success)
        }
    }
}
