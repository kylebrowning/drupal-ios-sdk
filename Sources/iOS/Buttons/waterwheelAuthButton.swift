//
//  waterwheelAuthButton.swift
//  Waterwheel 5.x — iOS only.
//

#if os(iOS)
import UIKit

/// Button action state.
public enum AuthAction: String {
    case login
    case logout
}

/// A `UIButton` subclass that stays in sync with ``Waterwheel/isLoggedIn``.
///
/// Assign closures to ``didPressLogin`` and ``didPressLogout`` to hook into
/// the button's taps. The button re-configures itself whenever Waterwheel
/// posts `waterwheelDidFinishRequest`, so it reflects the latest auth state.
@available(iOS 15.0, *)
open class waterwheelAuthButton: UIButton {

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
            name: .waterwheelDidFinishRequest,
            object: nil)

        translatesAutoresizingMaskIntoConstraints = false
        setTitleColor(UIButton(type: .system).titleColor(for: .normal), for: .normal)
        configureButton()
    }

    @objc open func configureButton() {
        if Waterwheel.shared.isLoggedIn {
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
                try await Waterwheel.shared.logout()
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
