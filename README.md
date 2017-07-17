![Connectivity](Connectivity.png)

[![CI Status](http://img.shields.io/travis/rwbutler/Connectivity.svg?style=flat)](https://travis-ci.org/rwbutler/Connectivity)
[![Version](https://img.shields.io/cocoapods/v/Connectivity.svg?style=flat)](http://cocoapods.org/pods/Connectivity)
[![License](https://img.shields.io/cocoapods/l/Connectivity.svg?style=flat)](http://cocoapods.org/pods/Connectivity)
[![Platform](https://img.shields.io/cocoapods/p/Connectivity.svg?style=flat)](http://cocoapods.org/pods/Connectivity)


Connectivity is a wrapper for Apple's [Reachability](https://developer.apple.com/library/content/samplecode/Reachability/Introduction/Intro.html) which provides a true indication of whether Internet connectivity is available. Connectivity's objective is to solve the captive portal problem whereby a device running iOS is connected to a WiFi network lacking Internet connectivity. Connectivity can detect such situations enabling you to react accordingly.

Ensure that you include Apple's Reachability header and implementation files ([Reachability.h and Reachability.m](https://developer.apple.com/library/content/samplecode/Reachability/Reachability.zip)) to use.

Use of Apple's Reachability is subject to [licensing from Apple](./Connectivity/Classes/Reachability/LICENSE.txt).

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

Connectivity is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Connectivity"
```

## Author

Ross Butler

## License

Connectivity is available under the MIT license. See the [LICENSE](./LICENSE) file for more info.
