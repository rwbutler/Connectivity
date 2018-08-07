Pod::Spec.new do |s|
  s.name             = 'Connectivity'
  s.version          = '0.0.2'
  s.summary          = 'Wraps Reachability to help developers determine where Internet connectivity is available'
  s.description      = <<-DESC
Connectivity is a wrapper for Reachability which provides a true indication of whether Internet connectivity is available. Connectivity's objective is to solve the captive portal problem whereby a device running iOS is connected to a WiFi network lacking Internet connectivity. Connectivity can detect such situations enabling you to react accordingly.
                       DESC

  s.homepage         = 'https://github.com/rwbutler/Connectivity'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'rwbutler' => 'github@rwbutler.com' }
  s.source           = { :git => 'https://github.com/rwbutler/Connectivity.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.swift_version = '4.1'
  s.source_files = 'Connectivity/Classes/**/*'
  s.exclude_files = [
    'Connectivity/Classes/Reachability/LICENSE.txt'
  ]

end
