//
//  DrupalLoginViewController.swift
//  DrupalIOSSDKUI — iOS only.
//

#if os(iOS)
import UIKit
import DrupalIOSSDK

@available(iOS 15.0, *)
open class DrupalLoginViewController: UIViewController {

    public let usernameField: UITextField = {
        let f = UITextField()
        f.autocorrectionType = .no
        f.autocapitalizationType = .none
        f.attributedPlaceholder = NSAttributedString(string: "Username")
        f.translatesAutoresizingMaskIntoConstraints = false
        f.backgroundColor = .secondarySystemBackground
        f.textAlignment = .center
        f.placeholder = "Username"
        f.isHidden = true
        return f
    }()

    public let passwordField: UITextField = {
        let f = UITextField()
        f.isSecureTextEntry = true
        f.autocorrectionType = .no
        f.autocapitalizationType = .none
        f.attributedPlaceholder = NSAttributedString(string: "Password")
        f.backgroundColor = .secondarySystemBackground
        f.textAlignment = .center
        f.translatesAutoresizingMaskIntoConstraints = false
        f.placeholder = "Password"
        f.isHidden = true
        f.returnKeyType = .go
        return f
    }()

    open var submitButton: DrupalAuthButton = {
        let b = DrupalAuthButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.backgroundColor = .systemGray
        return b
    }()

    open var cancelButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.backgroundColor = .systemGray2
        b.setTitle("Cancel", for: .normal)
        return b
    }()

    open var loginRequestCompleted: (_ success: Bool, _ error: Error?) -> Void = { _, _ in }
    open var logoutRequestCompleted: (_ success: Bool, _ error: Error?) -> Void = { _, _ in }
    open var cancelButtonHit: () -> Void = { }

    override open func viewDidLoad() {
        super.viewDidLoad()
        configure(isInit: true)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configure(isInit: false)
    }

    open func configure(isInit: Bool) {
        if isInit {
            view.backgroundColor = .systemBackground
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleRequestFinished),
                name: .drupalDidFinishRequest,
                object: nil)

            submitButton.didPressLogin = { [weak self] in self?.loginAction() }
            submitButton.didPressLogout = { [weak self] success, error in
                self?.logoutAction(success: success, error: error)
            }
            cancelButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)

            view.addSubview(usernameField)
            view.addSubview(passwordField)
            view.addSubview(submitButton)
            view.addSubview(cancelButton)
        }
        if !Drupal.shared.isLoggedIn {
            showAnonymousSubviews()
        }
    }

    @objc private func handleRequestFinished() {
        configure(isInit: false)
    }

    open func layoutSubviews() {
        layoutLoginField()
        layoutPasswordField()
        layoutSubmitButton()
        layoutCancelButton()
    }

    open func layoutLoginField() {
        usernameField.constrainEqual(.leadingMargin, to: view)
        usernameField.constrainEqual(.trailingMargin, to: view)
        usernameField.constrainEqual(.top, to: view, .top, multiplier: 1.0, constant: 44)
        usernameField.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
    }

    open func layoutPasswordField() {
        passwordField.constrainEqual(.leadingMargin, to: view)
        passwordField.constrainEqual(.trailingMargin, to: view)
        passwordField.constrainEqual(.bottomMargin, to: usernameField, .bottomMargin, multiplier: 1.0, constant: 55)
        passwordField.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
    }

    open func layoutSubmitButton() {
        submitButton.constrainEqual(.leadingMargin, to: view)
        submitButton.constrainEqual(.trailingMargin, to: view)
        submitButton.constrainEqual(.bottomMargin, to: passwordField, .bottomMargin, multiplier: 1.0, constant: 55)
        submitButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
    }

    open func layoutCancelButton() {
        cancelButton.constrainEqual(.leadingMargin, to: view)
        cancelButton.constrainEqual(.trailingMargin, to: view)
        cancelButton.constrainEqual(.bottomMargin, to: submitButton, .bottomMargin, multiplier: 1.0, constant: 55)
        cancelButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
    }

    open func hideAnonymousSubviews() {
        usernameField.isHidden = true
        passwordField.isHidden = true
        cancelButton.isHidden = true
    }

    open func showAnonymousSubviews() {
        layoutSubviews()
        usernameField.isHidden = false
        passwordField.isHidden = false
        cancelButton.isHidden = false
    }

    open func loginAction() {
        let username = usernameField.text ?? ""
        let password = passwordField.text ?? ""
        Task { @MainActor in
            do {
                _ = try await Drupal.shared.login(username: username, password: password)
                self.hideAnonymousSubviews()
                self.loginRequestCompleted(true, nil)
            } catch {
                self.loginRequestCompleted(false, error)
            }
        }
    }

    open func logoutAction(success: Bool, error: Error?) {
        if success { showAnonymousSubviews() }
        logoutRequestCompleted(success, error)
    }

    @objc open func cancelAction() {
        cancelButtonHit()
    }
}

#endif
