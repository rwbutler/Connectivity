![Connectivity](https://github.com/rwbutler/Connectivity/raw/master/docs/images/connectivity-banner.png)

[![CI Status](http://img.shields.io/travis/rwbutler/Connectivity.svg?style=flat)](https://travis-ci.org/rwbutler/Connectivity)
[![Version](https://img.shields.io/cocoapods/v/Connectivity.svg?style=flat)](http://cocoapods.org/pods/Connectivity)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Maintainability](https://api.codeclimate.com/v1/badges/c3041fef8e33cc4d00df/maintainability)](https://codeclimate.com/github/rwbutler/Connectivity/maintainability)
[![License](https://img.shields.io/cocoapods/l/Connectivity.svg?style=flat)](http://cocoapods.org/pods/Connectivity)
[![Platform](https://img.shields.io/cocoapods/p/Connectivity.svg?style=flat)](http://cocoapods.org/pods/Connectivity)
[![Swift 4.2](https://img.shields.io/badge/Swift-4.2-orange.svg?style=flat)](https://swift.org/)
[![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)

Connectivity is a wrapper for Apple's [Reachability](https://developer.apple.com/library/content/samplecode/Reachability/Introduction/Intro.html) providing a reliable measure of whether Internet connectivity is available where Reachability alone can only indicate whether _an interface is available that might allow a connection_.

Connectivity's objective is to solve the captive portal problem whereby an iOS device is connected to a WiFi network lacking Internet connectivity. Such situations are commonplace and may occur for example when connecting to a public WiFi network which requires the user to register before use. Connectivity can detect such situations enabling you to react accordingly.

To learn more about how to use Connectivity, take a look at the [keynote presentation](https://github.com/rwbutler/Connectivity/blob/master/docs/presentations/connectivity.pdf), check out the [blog post](https://medium.com/@rwbutler/solving-the-captive-portal-problem-on-ios-9a53ba2b381e), or make use of the table of contents below:

- [Features](#features)
- [What's New in Connectivity 2.0.0?](#whats-new-in-connectivity-200)
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
	- [Response Validation](#response-validation)
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

## What's new in Connectivity 2.0.0?

Connectivity 2.0.0 provides the option of using the new `Network` framework on iOS 12 and above. To make use of this functionality set the `framework` property to `.network` as follows:

```swift
let connectivity = Connectivity()
connectivity.framework = .network
```

Below iOS 12, Connectivity will default to the traditional behaviour of using `Reachability` to determine the availability of network interfaces.

For more information, refer to [CHANGELOG.md](CHANGELOG.md).

## Installation

Ensure that you include Apple's Reachability header and implementation files ([Reachability.h and Reachability.m](https://developer.apple.com/library/content/samplecode/Reachability/Reachability.zip)) to use.

Use of Apple's Reachability is subject to [licensing from Apple](./Connectivity/Classes/Reachability/LICENSE.txt).

### Cocoapods

[CocoaPods](http://cocoapods.org) is a dependency manager which integrates dependencies into your Xcode workspace. To install it using [Ruby gems](https://rubygems.org/) run:

```bash
gem install cocoapods
```

To install Connectivity using Cocoapods, simply add the following line to your Podfile:

```ruby
pod "Connectivity"
```

Then run the command:

```ruby
pod install
```

For more information [see here](https://cocoapods.org/#getstarted).

### Carthage

Carthage is a dependency manager which produces a binary for manual integration into your project. It can be installed via [Homebrew](https://brew.sh/) using the commands:

```bash
brew update
brew install carthage
```

In order to integrate Connectivity into your project via Carthage, add the following line to your project's Cartfile:

```ogdl
github "rwbutler/Connectivity"
```

From the macOS Terminal run `carthage update --platform iOS` to build the framework then drag `Connectivity.framework` into your Xcode project.

For more information [see here](https://github.com/Carthage/Carthage#quick-start).

## How It Works

iOS adopts a protocol called Wireless Internet Service Provider roaming ([WISPr 2.0](https://www.wballiance.com/glossary/)) published by the [Wireless Broadband Alliance](https://www.wballiance.com/). This protocol defines the Smart Client to Access Gateway interface describing how to authenticate users accessing public IEEE 802.11 (Wi-Fi) networks using the [Universal Access Method](https://en.wikipedia.org/wiki/Universal_access_method) in which a captive portal presents a login page to the user. 

The user must then register or provide login credentials via a web browser in order to be granted access to the network using [RADIUS](https://www.cisco.com/c/en/us/support/docs/security-vpn/remote-authentication-dial-user-service-radius/12433-32.html) or another protocol providing centralized Authentication, Authorization, and Accounting ([AAA](https://en.wikipedia.org/wiki/AAA_(computer_security))).

In order to detect a that it has connected to a Wi-Fi network with a captive portal, iOS contacts a number of endpoints hosted by Apple - an example being [https://www.apple.com/library/test/success.html](https://www.apple.com/library/test/success.html). Each endpoint hosts a small HTML page of the form:

```html

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN">
<HTML>
<HEAD>
	<TITLE>Success</TITLE>
</HEAD>
<BODY>
	Success
</BODY>
</HTML>

```

If on downloading this small HTML page iOS finds that it contains the word `Success` as above then it knows that Internet connectivity is available. However, if a login page is presented by a captive portal then the word `Success` will not be present and iOS will realize that the network connection has been hijacked by a captive portal and will present a browser window allowing the user to login or register.

Apple hosts a number of these pages such that should one of these pages go down, a number of fallbacks can be checked to determine whether connectivity is present or whether our connection is blocked by the presence of a captive portal. Unfortunately iOS exposes no framework to developers which allows us to make use of the operating system’s awareness of captive portals.

Connectivity is an open-source framework which wraps Reachability and endeavours to replicate iOS’s means of detecting captive portals. When Reachability detects Wi-Fi or WWAN connectivity, Connectivity contacts a number of endpoints to determine whether true Internet connectivity is present or whether a captive portal is intercepting the connections. This approach can also be used to determine whether an iOS device is connected to a Wi-Fi router with no Internet access. 

Connectivity provides an interface as close to Reachability as possible so that it is familiar to developers used to working with Reachability. This includes providing the methods `startNotifier()` and `stopNotifier()` to begin checking for changes in Internet connectivity. Once the notifier has been started, you may query for the current connectivity status synchronously using the `status` property (similar to Reachability’s `currentReachabilityStatus`) or asynchronously by registering as an observer with the default NotificationCenter for the notification `kNetworkConnectivityChangedNotification` (in Swift this is accessed through `Notification.Name.ConnectivityDidChange`) — similar to Reachability’s notification `kNetworkReachabilityChangedNotification`.

By default, Connectivity contacts a number of endpoints already used by iOS but it recommended that these are supplemented by endpoints hosted by the developer by appending to the `connectivityURLs` property. Further customization is possible through setting the `successThreshold` property which determines the percentage of endpoints contacted which must result in a successful check in order to conclude that connectivity is present. The default value specifies that 75% of URLs contacted must result in a successful connectivity check.

## Usage

For an example of how to use Connectivity, see the sample app in the [Example](./Example) directory.

### Callbacks

To get started using Connectivity, simply instantiate an instance and assign a closure to be invoked when Connectivity detects that you are connected to the Internet, when disconnected, or in both cases as follows:

```swift
let connectivity: Connectivity = Connectivity()

let connectivityChanged: (Connectivity) -> Void = { [weak self] connectivity in
     self?.updateConnectionStatus(connectivity.status)
}

connectivity.whenConnected = connectivityChanged
connectivity.whenDisconnected = connectivityChanged

func updateConnectionStatus(_ status: Connectivity.ConnectivityStatus) {

    switch status {
      case .connected:
	    case .connectedViaWiFi:
	    case .connectedViaWiFiWithoutInternet:
	    case .connectedViaWWAN:
	    case .connectedViaWWANWithoutInternet:
	    case .notConnected:
    }
        
}
```

Then to start listening for changes in Connectivity call:

```swift
connectivity.startNotifier()
```

Then remember to call `connectivity.stopNotifier()` when you are done.

### One-Off Checks

Sometimes you only want to check the connectivity state as a one-off. To do so, instantiate a Connectivity object then check the status property as follows:

```swift
let connectivity = Connectivity()

connectivity.checkConnectivity { connectivity in

	switch connectivity.status {
		case .connected: 
			break
		case .connectedViaWiFi:
			break
		case .connectedViaWiFiWithoutInternet:
			break
		case .connectedViaWWAN:
			break
		case .connectedViaWWANWithoutInternet:
			break
		case .notConnected:
			break
	}

}
```

Alternatively, you may check the following properties of the `Connectivity` object directly if you are only interested in certain types of connections:

```swift
var isConnectedViaCellular: Bool

var isConnectedViaWiFi: Bool
    
var isConnectedViaCellularWithoutInternet: Bool

var isConnectedViaWiFiWithoutInternet: Bool
```

### Connectivity URLs

It is possible to set the URLs which will be contacted to check connectivity via the `connectivityURLs` property of the `Connectivity` object before starting connectivity checks with `startNotifier()`.

```swift
connectivity.connectivityURLs = [URL(string: "https://www.apple.com/library/test/success.html")!]
```

### Notifications

If you prefer using notifications to observe changes in connectivity, you may add an observer on the default NotificationCenter:

[`NotificationCenter.default.addObserver(_:selector:name:object:)`](https://developer.apple.com/documentation/foundation/notificationcenter/1415360-addobserver)

Listening for `Notification.Name.ConnectivityDidChange`, the `object` property of received notifications will contain the `Connectivity` object which you can use to query connectivity status.

### Polling

In certain cases you may need to be kept constantly apprised of changes in connectivity state and therefore may wish to enable polling. Where enabled, Connectivity will not wait on changes in Reachability state but will poll the connectivity URLs every 10 seconds (this value is configurable). `ConnectivityDidChange` notifications and the closures assigned to the `whenConnected` and `whenDisconnected` properties will be invoked only where changes in connectivity state occur.

To enable polling:

```swift
connectivity.isPollingEnabled = true
connectivity.startNotifier()
```

As always, remember to call `stopNotifier()` when you are done.

### SSL

As of Connectivity 1.1.0, using HTTPS for connectivity URLs is the default setting. If your app doesn't make use of [App Transport Security](https://developer.apple.com/security/) and you wish to make use of HTTP URLs as well as HTTPS ones then either set `isHTTPSOnly` to `false` or set `shouldUseHTTPS` to `false` when instantiating the Connectivity object as follows*:

```swift
let connectivity = Connectivity(shouldUseHTTPS: false)
```

*Note that the property will not be set if you have not set the `NSAllowsArbitraryLoads` flag in your app's Info.plist first.

### Threshold

To set the number of successful connections required in order to be deemed successfully connected, set the `successThreshold` property. The value is specified as a percentage indicating the percentage of successful connections i.e. if four connectivity URLs are set in the `connectivityURLs` property and a threshold of 75% is specified then three out of the four checks must succeed in order for our app to be deemed connected:

```swift
connectivity.successThreshold = Connectivity.Percentage(75.0)
```

### Response Validation

There are three different validation modes available for checking response content these being:

- `.containsExpectedResponseString` - Checks that the response *contains* the expected response as defined by the `expectedResponseString` property. 
- `.equalsExpectedResponseString` - Checks that the response *equals* the expected response as defined by the `expectedResponseString` property. 
- `.matchesRegularExpression` - Checks that the response matches the regular expression as defined by the `expectedResponseRegEx` property.

## Author

[Ross Butler](https://github.com/rwbutler)

## License

Connectivity is available under the MIT license. See the [LICENSE file](./LICENSE) for more info.

## Additional Software

### Controls

* [AnimatedGradientView](https://github.com/rwbutler/AnimatedGradientView) - Powerful gradient animations made simple for iOS.

|[AnimatedGradientView](https://github.com/rwbutler/AnimatedGradientView) |
|:-------------------------:|
|[![AnimatedGradientView](https://raw.githubusercontent.com/rwbutler/AnimatedGradientView/master/docs/images/animated-gradient-view-logo.png)](https://github.com/rwbutler/AnimatedGradientView) 

### Frameworks

* [Cheats](https://github.com/rwbutler/Cheats) - Retro cheat codes for modern iOS apps.
* [Connectivity](https://github.com/rwbutler/Connectivity) - Improves on Reachability for determining Internet connectivity in your iOS application.
* [FeatureFlags](https://github.com/rwbutler/FeatureFlags) - Allows developers to configure feature flags, run multiple A/B or MVT tests using a bundled / remotely-hosted JSON configuration file.
* [Skylark](https://github.com/rwbutler/Skylark) - Fully Swift BDD testing framework for writing Cucumber scenarios using Gherkin syntax.
* [TailorSwift](https://github.com/rwbutler/TailorSwift) - A collection of useful Swift Core Library / Foundation framework extensions.
* [TypographyKit](https://github.com/rwbutler/TypographyKit) - Consistent & accessible visual styling on iOS with Dynamic Type support.
* [Updates](https://github.com/rwbutler/Updates) - Automatically detects app updates and gently prompts users to update.

|[Cheats](https://github.com/rwbutler/Cheats) |[Connectivity](https://github.com/rwbutler/Connectivity) | [FeatureFlags](https://github.com/rwbutler/FeatureFlags) | [Skylark](https://github.com/rwbutler/Skylark) | [TypographyKit](https://github.com/rwbutler/TypographyKit) | [Updates](https://github.com/rwbutler/Updates) |
|:-------------------------:|:-------------------------:|:-------------------------:|:-------------------------:|:-------------------------:|:-------------------------:|
|[![Cheats](https://raw.githubusercontent.com/rwbutler/Cheats/master/docs/images/cheats-logo.png)](https://github.com/rwbutler/Cheats) |[![Connectivity](https://github.com/rwbutler/Connectivity/raw/master/ConnectivityLogo.png)](https://github.com/rwbutler/Connectivity) | [![FeatureFlags](https://raw.githubusercontent.com/rwbutler/FeatureFlags/master/docs/images/feature-flags-logo.png)](https://github.com/rwbutler/FeatureFlags) | [![Skylark](https://github.com/rwbutler/Skylark/raw/master/SkylarkLogo.png)](https://github.com/rwbutler/Skylark) | [![TypographyKit](https://raw.githubusercontent.com/rwbutler/TypographyKit/master/docs/images/typography-kit-logo.png)](https://github.com/rwbutler/TypographyKit) | [![Updates](https://raw.githubusercontent.com/rwbutler/Updates/master/docs/images/updates-logo.png)](https://github.com/rwbutler/Updates)

### Tools

* [Config Validator](https://github.com/rwbutler/ConfigValidator) - Config Validator validates & uploads your configuration files and cache clears your CDN as part of your CI process.
* [IPA Uploader](https://github.com/rwbutler/IPAUploader) - Uploads your apps to TestFlight & App Store.
* [Palette](https://github.com/rwbutler/TypographyKitPalette) - Makes your [TypographyKit](https://github.com/rwbutler/TypographyKit) color palette available in Xcode Interface Builder.

|[Config Validator](https://github.com/rwbutler/ConfigValidator) | [IPA Uploader](https://github.com/rwbutler/IPAUploader) | [Palette](https://github.com/rwbutler/TypographyKitPalette)|
|:-------------------------:|:-------------------------:|:-------------------------:|
|[![Config Validator](https://raw.githubusercontent.com/rwbutler/ConfigValidator/master/docs/images/config-validator-logo.png)](https://github.com/rwbutler/ConfigValidator) | [![IPA Uploader](https://raw.githubusercontent.com/rwbutler/IPAUploader/master/docs/images/ipa-uploader-logo.png)](https://github.com/rwbutler/IPAUploader) | [![Palette](https://raw.githubusercontent.com/rwbutler/TypographyKitPalette/master/docs/images/typography-kit-palette-logo.png)](https://github.com/rwbutler/TypographyKitPalette)