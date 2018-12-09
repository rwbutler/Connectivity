Pod::Spec.new do |s|
  s.name             = 'Connectivity'
  s.version          = '2.0.0'
  s.summary          = 'Makes Internet connectivity detection more robust by detecting Wi-Fi networks without Internet access.'
  s.description      = <<-DESC
Connectivity wraps Apple's Reachability code to provide a reliable measure of whether Internet connectivity is available where Reachability alone can only indicate whether _an interface is available that might allow a connection_. Connectivity's objective is to solve the captive portal problem whereby an iOS device is connected to a Wi-Fi network lacking Internet connectivity. Such situations are commonplace and may occur for example when connecting to a public Wi-Fi network which requires the user to register before use. Connectivity can detect such situations enabling you to react accordingly.
                       DESC

  s.homepage         = 'https://github.com/rwbutler/Connectivity'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'rwbutler' => 'github@rwbutler.com' }
  s.source           = { :git => 'https://github.com/rwbutler/Connectivity.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.swift_version = '4.2'
  s.source_files = 'Connectivity/Classes/**/*'
  s.exclude_files = [
    'Connectivity/Classes/Reachability/LICENSE.txt'
  ]

end