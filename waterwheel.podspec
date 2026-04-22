Pod::Spec.new do |s|
  s.name         = "waterwheel"
  s.version      = "5.0.0"
  s.summary      = "Swift SDK for the Drupal 10/11 RESTful Web Services API."
  s.description  = <<-DESC
    Waterwheel is a pure-Foundation Swift SDK for talking to a Drupal site over
    the core RESTful Web Services API. Zero third-party dependencies,
    async/await, cookie + basic + bearer authentication, automatic CSRF token
    management, and optional iOS UI helpers (auth button, login VC, views).
  DESC
  s.homepage     = "https://github.com/kylebrowning/waterwheel-swift"
  s.author       = { "Kyle Browning" => "kylebrowning@me.com" }
  s.source       = { :git => "https://github.com/kylebrowning/waterwheel-swift.git", :tag => s.version }
  s.source_files = 'Sources/**/**/*.swift'
  s.requires_arc = true

  s.swift_versions = ['5.9']

  s.ios.deployment_target     = '15.0'
  s.osx.deployment_target     = '12.0'
  s.tvos.deployment_target    = '15.0'
  s.watchos.deployment_target = '8.0'

  # iOS-only UI helpers are #if os(iOS) guarded, but we still exclude the
  # directory on non-iOS platforms so the module has fewer files to scan.
  s.osx.exclude_files     = 'Sources/iOS'
  s.tvos.exclude_files    = 'Sources/iOS'
  s.watchos.exclude_files = 'Sources/iOS'

  s.license  = { :type => 'MPL 1.1/GPL 2.0', :file => "LICENSE" }
end
