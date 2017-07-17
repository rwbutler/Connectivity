#
# Be sure to run `pod lib lint Connectivity.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Connectivity'
  s.version          = '0.0.1'
  s.summary          = 'Wraps Reachability to help developers determine where Internet connectivity is available'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Connectivity is a wrapper for Reachability which provides a true indication of whether Internet connectivity is available. Connectivity's objective is to solve the captive portal problem whereby a device running iOS is connected to a WiFi network lacking Internet connectivity. Connectivity can detect such situations enabling you to react accordingly.
                       DESC

  s.homepage         = 'https://github.com/rwbutler/Connectivity'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'rwbutler' => 'github@rwbutler.com' }
  s.source           = { :git => 'https://github.com/rwbutler/Connectivity.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'Connectivity/Classes/**/*'
  
  # s.resource_bundles = {
  #   'Connectivity' => ['Connectivity/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
