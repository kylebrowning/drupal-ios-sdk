//
//  DrupalAuthButton.swift
//  DrupalIOSSDKUI — iOS only.
//

#if os(iOS)
import UIKit
import DrupalIOSSDK

/// Button action state.
public enum AuthAction: String {
    case login
    case logout
}

/// A `UIButton` subclass that stays in sync with ``Drupal/isLoggedIn``.
///
/// Assign closures to ``didPressLogin`` and ``didPressLogout`` to hook into
/// the button's taps. The button re-configures itself whenever the SDK posts
/// `.drupalDidFinishRequest`, so it always reflects the latest auth state.
@available(iOS 15.0, *)
open class DrupalAuthButton: UIButton {

    open var didPressLogin: () -> Void = { }
    open var didPressLogout: (_ success: Bool, _ error: Error?) -> Void = { _, _ in }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initButton()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initButton()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func initButton() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configureButton),
            name: .drupalDidFinishRequest,
            object: nil)

        translatesAutoresizingMaskIntoConstraints = false
        setTitleColor(UIButton(type: .system).titleColor(for: .normal), for: .normal)
        configureButton()
    }

    @objc open func configureButton() {
        if Drupal.shared.isLoggedIn {
            setTitle("Logout", for: .normal)
            removeTarget(self, action: #selector(loginAction), for: .touchUpInside)
            addTarget(self, action: #selector(logoutAction), for: .touchUpInside)
        } else {
            setTitle("Login", for: .normal)
            removeTarget(self, action: #selector(logoutAction), for: .touchUpInside)
            addTarget(self, action: #selector(loginAction), for: .touchUpInside)
        }
    }

    @objc open func logoutAction() {
        Task { @MainActor in
            do {
                try await Drupal.shared.logout()
                self.didPressLogout(true, nil)
            } catch {
                self.didPressLogout(false, error)
            }
        }
    }

    @objc open func loginAction() {
        didPressLogin()
    }
}

#endif
