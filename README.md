![Connectivity](https://github.com/rwbutler/Connectivity/raw/master/Connectivity.png)

[![CI Status](http://img.shields.io/travis/rwbutler/Connectivity.svg?style=flat)](https://travis-ci.org/rwbutler/Connectivity)
[![Version](https://img.shields.io/cocoapods/v/Connectivity.svg?style=flat)](http://cocoapods.org/pods/Connectivity)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/Connectivity.svg?style=flat)](http://cocoapods.org/pods/Connectivity)
[![Platform](https://img.shields.io/cocoapods/p/Connectivity.svg?style=flat)](http://cocoapods.org/pods/Connectivity)


Connectivity is a wrapper for Apple's [Reachability](https://developer.apple.com/library/content/samplecode/Reachability/Introduction/Intro.html) providing a reliable measure of whether Internet connectivity is available where Reachability alone can only indicate whether _an interface is available that might allow a connection_.

Connectivity's objective is to solve the captive portal problem whereby an iOS device is connected to a WiFi network lacking Internet connectivity. Such situations are commonplace and may occur for example when connecting to a public WiFi network which requires the user to register before use. Connectivity can detect such situations enabling you to react accordingly.

To learn more about how to use Connectivity, take a look at the [keynote presentation](https://github.com/rwbutler/Connectivity/blob/master/docs/presentations/connectivity.pdf), check out the [blog post](https://medium.com/@rwbutler/beyond-reachability-detecting-true-internet-connectivity-on-ios-928da1b60122), or make use of the table of contents below:

- [Features](#features)
- [Installation](#installation)
	- [Cocoapods](#cocoapods)
	- [Carthage](#carthage)
- [How It Works](#how-it-works)
- [Usage](#usage)
	- [Callbacks](#callbacks)
	- [One-Off Checks](#one-off-checks)
	- [Connectivity URLs](#connectivity-urls)
	- [Notifications](#notifications)
	- [Polling](#polling)
	- [SSL](#ssl)
	- [Threshold](#threshold)
- [Author](#author)
- [License](#license)
- [Additional Software](#additional-software)
	- [Frameworks](#frameworks)
	- [Tools](#tools)

## Features

- [x] Detect captive portals when a device joins a network.
- [x] Detect when connected to a router that has no Internet access.
- [x] Be notified of changes in Internet connectivity.
- [x] Polling connectivity checks may be performed where a constant network connection is required (optional).

## Installation

Ensure that you include Apple's Reachability header and implementation files ([Reachability.h and Reachability.m](https://developer.apple.com/library/content/samplecode/Reachability/Reachability.zip)) to use.

Use of Apple's Reachability is subject to [licensing from Apple](./Connectivity/Classes/Reachability/LICENSE.txt).

### Cocoapods

[CocoaPods](http://cocoapods.org) is a dependency manager which integrates dependencies into your Xcode workspace. To install it using [Ruby gems](https://rubygems.org/) run:

```
gem install cocoapods
```

To install Connectivity using Cocoapods, simply add the following line to your Podfile:

```
pod "Connectivity"
```

Then run the command:

```
pod install
```

For more information [see here](https://cocoapods.org/#getstarted).

### Carthage

Carthage is a dependency manager which produces a binary for manual integration into your project. It can be installed via [Homebrew](https://brew.sh/) using the commands:

```
brew update
brew install carthage
```

In order to integrate Connectivity into your project via Carthage, add the following line to your project's Cartfile:

```
github "rwbutler/Connectivity"
```

From the macOS Terminal run `carthage update --platform iOS` to build the framework then drag `Connectivity.framework` into your Xcode project.

For more information [see here](https://github.com/Carthage/Carthage#quick-start).

## How It Works


## Usage

For an example of how to use Connectivity, see the sample app in the [Example](./Example) directory.

### Callbacks

To get started using Connectivity, simply instantiate an instance and assign a closure to be invoked when Connectivity detects that you are connected to the Internet, when disconnected, or in both cases as follows:

```
let connectivity: Connectivity = Connectivity()

let connectivityChanged: (Connectivity) -> Void = { [weak self] connectivity in
     self?.updateConnectionStatus(connectivity.status)
}

connectivity.whenConnected = connectivityChanged
connectivity.whenDisconnected = connectivityChanged

func updateConnectionStatus(_ status: Connectivity.ConnectivityStatus) {

    switch status {
	    case .connectedViaWiFi:
	    case .connectedViaWiFiWithoutInternet:
	    case .connectedViaWWAN:
	    case .connectedViaWWANWithoutInternet:
	    case .notConnected:
    }
        
}
```

Then to start listening for changes in Connectivity call:

```
connectivity.startNotifier()
```

Then remember to call `connectivity.stopNotifier()` when you are done.

### One-Off Checks

Sometimes you only want to check the connectivity state as a one-off. To do so, instantiate a Connectivity object then check the status property as follows:

```
let connectivity = Connectivity()

switch connectivity.status {

	case .connectedViaWiFi:
	
	case .connectedViaWiFiWithoutInternet:
	
	case .connectedViaWWAN:
	
	case .connectedViaWWANWithoutInternet:
	
	case .notConnected:
	
}
```

Alternatively, you may check the following properties of the `Connectivity` object directly if you are only interested in certain types of connections:

```
var isConnectedViaWWAN: Bool

var isConnectedViaWiFi: Bool
    
var isConnectedViaWWANWithoutInternet: Bool

var isConnectedViaWiFiWithoutInternet: Bool
```

### Connectivity URLs

It is possible to set the URLs which will be contacted to check connectivity via the `connectivityURLs` property of the `Connectivity` object before starting connectivity checks with `startNotifier()`.

```
connectivity.connectivityURLs = [URL(string: “https://www.apple.com/library/test/success.html")!]
```

### Notifications

If you prefer using notifications to observe changes in connectivity, you may add an observer on the default NotificationCenter:

[`NotificationCenter.default.addObserver(_:selector:name:object:)`](https://developer.apple.com/documentation/foundation/notificationcenter/1415360-addobserver)

Listening for `Notification.Name.ConnectivityDidChange`, the `object` property of received notifications will contain the `Connectivity` object which you can use to query connectivity status.

### Polling

In certain cases you may need to be kept constantly apprised of changes in connectivity state and therefore may wish to enable polling. Where enabled, Connectivity will not wait on changes in Reachability state but will poll the connectivity URLs every 10 seconds (this value is configurable). `ConnectivityDidChange` notifications and the closures assigned to the `whenConnected` and `whenDisconnected` properties will be invoked only where changes in connectivity state occur.

To enable polling:

```
connectivity.isPollingEnabled = true
connectivity.startNotifier()
```

As always, remember to call `stopNotifier()` when you are done.

### SSL

As of Connectivity 1.1.0, using HTTPS for connectivity URLs is the default setting. If your app doesn't make use of [App Transport Security](https://developer.apple.com/security/) and you wish to make use of HTTP URLs as well as HTTPS ones then either set `isHTTPSOnly` to `false` or set `shouldUseHTTPS` to `false` when instantiating the Connectivity object as follows*:

```
let connectivity = Connectivity(shouldUseHTTPS: false)
```

*Note that the property will not be set if you have not set the `NSAllowsArbitraryLoads` flag in your app's Info.plist first.

### Threshold

To set the number of successful connections required in order to be deemed successfully connected, set the `successThreshold` property. The value is specified as a percentage indicating the percentage of successful connections i.e. if four connectivity URLs are set in the `connectivityURLs` property and a threshold of 75% is specified then three out of the four checks must succeed in order for our app to be deemed connected:

```
connectivity.successThreshold = Connectivity.Percentage(75.0)
```

## Author

[Ross Butler](https://github.com/rwbutler/)

## License

Connectivity is available under the MIT license. See the [LICENSE](./LICENSE) file for more info.

## Additional Software

### Frameworks

* [Connectivity](https://github.com/rwbutler/Connectivity) - Improves on Reachability for determining Internet connectivity in your iOS application.
* [FeatureFlags](https://github.com/rwbutler/FeatureFlags) - Allows developers to configure feature flags, run multiple A/B or MVT tests using a bundled / remotely-hosted JSON configuration file.
* [Skylark](https://github.com/rwbutler/Skylark) - Fully Swift BDD testing framework for writing Cucumber scenarios using Gherkin syntax.
* [TailorSwift](https://github.com/rwbutler/TailorSwift) - A collection of useful Swift Core Library / Foundation framework extensions.
* [TypographyKit](https://github.com/rwbutler/TypographyKit) - Consistent & accessible visual styling on iOS with Dynamic Type support.

### Tools
* [Palette](https://github.com/rwbutler/TypographyKitPalette) - Makes your [TypographyKit](https://github.com/rwbutler/TypographyKit) color palette available in Xcode Interface Builder.


[Connectivity](https://github.com/rwbutler/Connectivity)          |  [FeatureFlags](https://github.com/rwbutler/FeatureFlags)          | [Skylark](https://github.com/rwbutler/Skylark) | [TypographyKit](https://github.com/rwbutler/TypographyKit) | [Palette](https://github.com/rwbutler/TypographyKitPalette)
:-------------------------:|:-------------------------:|:-------------------------:|:-------------------------:|:-------------------------:
[![Connectivity](https://github.com/rwbutler/Connectivity/raw/master/ConnectivityLogo.png)](https://github.com/rwbutler/Connectivity)   | [![FeatureFlags](https://raw.githubusercontent.com/rwbutler/FeatureFlags/master/docs/images/feature-flags-logo.png)](https://github.com/rwbutler/FeatureFlags)   | [![Skylark](https://github.com/rwbutler/Skylark/raw/master/SkylarkLogo.png)](https://github.com/rwbutler/Skylark) |  [![TypographyKit](https://github.com/rwbutler/TypographyKit/raw/master/TypographyKitLogo.png)](https://github.com/rwbutler/TypographyKit) | [![Palette](https://github.com/rwbutler/TypographyKitPalette/raw/master/PaletteLogo.png)](https://github.com/rwbutler/TypographyKitPalette)

