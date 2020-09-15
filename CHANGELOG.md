# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [5.0.0] - 2020-09-15
### Added
- Support for Xcode 12.

### Changed
- Dropped support for iOS 8

## [4.2.0] - 2020-08-08
### Added
- Support for macOS.

### Changed
- Fixes Swift Package Manager integration.

## [4.1.0] - 2020-07-07
### Added
- Added `checkWhenApplicationDidBecomeActive` flag which when enabled will check connectivity status when an app returns from the background.
- Added `pollWhileOfflineOnly` flag which ensures that Connectivity only polls after recording an unsuccessful connection result. Following a successful result polling will cease.

### Changed
- The entirety of the logic that was previously in `checkConnectivity` is now offloaded to `internalQueue` immediately.
- Where polling, it was possible for a successful connection check to not be able to report the network interface used (as Reachability returned `NotReachable`) where using the `.systemConfiguration` framework option. In this instance, Connectivity now uses `NWPathMonitor` as a fallback on iOS 12+ even where `.systemConfiguration` is the selected option.

## [4.0.0] - 2020-05-05
### Added
- `Connectivity.Publisher` introduced providing support for Combine in iOS 13.0.

## [3.3.4] - 2020-04-21
### Changed
- Lowered the default connectivity threshold to 50% as it was recently reported that in certain parts of the world the recently added iOS 13 connectivity URL is inaccessible causing an offline result to be returned with the previous default threshold of 75% and only the two example connectivity URLs used. See [issue #41](https://github.com/rwbutler/Connectivity/issues/41).

## [3.3.3] - 2019-11-18
### Changed
- Added iOS 13 URL to default connectivity URLs.

## [3.3.2] - 2019-11-14
### Changed
- Made `ConnectivityStatus` enum Objective-C compatible.

## [3.3.1] - 2019-11-13
### Changed
- Made `ConnectivityFramework` enum Objective-C compatible.

## [3.3.0] - 2019-11-04
### Added
- Added new validators including:

	- `ConnectivityResponseStringEqualityValidator`: Determines whether the response string is equal to an expected string.
	- `ConnectivityResponseContainsStringValidator`: Determines whether the response string contains an expected string.
	- `ConnectivityResponseRegExValidator`: Determines whether the response string matches a given regular expression.

These validators can be composed when creating a custom validator conforming to `ConnectivityResponseValidator` protocol.

## [3.2.0] - 2019-10-22
### Added
- Property `validationMode` on the Connectivity object may now take a value of `.custom` allowing an implementation of `ConnectivityResponseValidator` protocol to be supplied to the `responseValidator` property. This custom validator will be used to validate the response returned when accessing the connectivity URLs.

## [3.1.2] - 2019-10-02
### Changed
- Updated podspec to include `Network.framework` as part of the `weak_frameworks` entry rather than as part of `frameworks`.

## [3.1.1] - 2019-09-03
### Changed
- Fixed missing framework dependencies in podspec, see [Issue #24](https://github.com/rwbutler/Connectivity/issues/24).

## [3.1.0] - 2019-08-08
### Added
- Properties `availableInterfaces` and `currentInterface` indicate the network interfaces used in the most recent connectivity check.
- New `Connectivity.Status` case `.determining` will be returned prior to a connectivity check having completed.
### Changed
- Refactor of `status` property which is now set on most recent connectivity check rather than computed on read.

## [3.0.4] - 2019-08-01
### Changed
- Ensure reading from and writing to the `path` property occurs in a thread-safe manner.

## [3.0.3] - 2019-08-01
### Changed
- Removed superfluous `canImport` around properties using `Network` framework.

## [3.0.2] - 2019-07-03
### Added
- Support for Swift Package Manager where using Xcode 11.0 beta.

## [3.0.1] - 2019-06-04
### Changed
- Makes Connectivity a `NSObject` subclass for compatibility with Objective-C.

## [3.0.0] - 2019-04-02
### Changed
- Now targets Swift 5.0 instead of Swift 4.2.

## [2.2.1] - 2019-03-26
### Changed
- Made the `Connectivity.Percentage` initializer `public`.

## [2.2.0] - 2019-02-04
### Added
- Added the ability to specify a bearer token for authorization by setting the `bearerToken` property.

## [2.1.0] - 2019-01-20
### Added
- Added the ability to determine the method used to validate the response returned by a connectivity endpoint.

## [2.0.4] - 2019-01-15
### Changed
- Added support for tvOS.

## [2.0.3] - 2019-01-09
### Changed
- Makes `pollingInterval` publicly accessible.

## [2.0.2] - 2019-01-08
### Changed
- Use `Timer.scheduledTimer(timeInterval:target:selector:userInfo:repeats:)` rather than `Timer.scheduledTimer(withTimeInterval:repeats:block:)` making polling available prior to iOS 10.

## [2.0.1] - 2019-01-02
### Changed
- Enabled `Allow app extension API only` in target deployment info.

## [2.0.0] - 2018-12-09
### Added
- Provided the ability to switch between Reachability and the Network framework (from iOS 12 onwards) using the new `framework` property on the `Connectivity` object. 
### Changed
- Makes a `checkConnectivity` call required to reliably query connectivity state for one-off checks (see the example app).
- Properties referring to `WWAN` have been renamed to `Cellular` e.g. `isConnectedViaWWAN` -> `isConnectedViaCellular`.

## [1.1.1] - 2018-11-23
### Changed
- Refactored code into smaller reusable functions to eliminate code duplication and improve maintainability.

## [1.1.0] - 2018-11-14

### Added
- Allows the polling interval to be configured.
- Exposes the `ConnectivityDidChange` notification name as part of the public interface.

### Changed
- Enforces SSL by default.

## [1.0.0] - 2018-09-20
### Changed
- Updated for Xcode 10 and Swift 4.2.

## [0.0.4] - 2018-08-18
### Changed
- Fixed an issue whereby the callback could be invoked more frequently than necessary if using the polling option.

## [0.0.3] - 2018-08-18
### Added
- Adds a sample application to demonstrate how to use Connectivity.
### Changed
- Improvements to code structure and an early exit mechanism such that once the required number of successful connectivity checks has been met any pending checks will be cancelled as they will no longer affect the result.

## [0.0.2] - 2018-08-07
### Changed
- This release introduces support for Swift 4 and integration using the Carthage dependency manager. In order to integrate Connectivity into your project via Carthage, add the following line to your project's Cartfile:

	```
	github "rwbutler/Connectivity"
	```

## [0.0.1] - 2018-07-27
### Added
- Connectivity is a framework which improves on Reachability by allowing developers to detect whether true Internet connectivity is available or whether a captive portal is blocking Internet traffic.