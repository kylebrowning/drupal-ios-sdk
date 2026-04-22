Pod::Spec.new do |s|
  s.name         = "DrupalIOSSDK"
  s.version      = "5.0.0"
  s.summary      = "Drupal iOS SDK — Swift SDK for the Drupal 10 / 11 RESTful Web Services API."
  s.description  = <<-DESC
    Drupal iOS SDK is a pure-Foundation Swift SDK for talking to a Drupal site
    over the core RESTful Web Services API. Zero third-party dependencies,
    async / await, cookie + basic + bearer authentication, and automatic
    CSRF token management.

    Ships two subspecs:
      * Core (default)        — the `DrupalIOSSDK` module (networking layer).
      * UI                    — the `DrupalIOSSDKUI` module with iOS UIKit
                                helpers (auth button, login VC, views table).
  DESC
  s.homepage     = "https://github.com/kylebrowning/drupal-ios-sdk"
  s.author       = { "Kyle Browning" => "kylebrowning@me.com" }
  s.source       = { :git => "https://github.com/kylebrowning/drupal-ios-sdk.git", :tag => s.version }
  s.requires_arc = true
  s.swift_versions = ['5.9']

  s.ios.deployment_target     = '15.0'
  s.osx.deployment_target     = '12.0'
  s.tvos.deployment_target    = '15.0'
  s.watchos.deployment_target = '8.0'

  s.license  = { :type => 'MPL 1.1/GPL 2.0', :file => "LICENSE" }

  s.default_subspecs = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = 'Sources/DrupalIOSSDK/*.swift'
  end

  s.subspec 'UI' do |ui|
    ui.ios.deployment_target = '15.0'
    ui.source_files = 'Sources/DrupalIOSSDKUI/*.swift'
    ui.dependency 'DrupalIOSSDK/Core'
    # UI is iOS only — exclude from the non-iOS platforms.
    ui.osx.source_files     = []
    ui.tvos.source_files    = []
    ui.watchos.source_files = []
  end
end
