# ti.admob.unified

A unified AdMob module for Titanium SDK that provides a consistent API across iOS and Android platforms with automatic compliance handling for GDPR, CCPA, and App Tracking Transparency.

[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-blue.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Titanium SDK](https://img.shields.io/badge/Titanium%20SDK-12.8.0%2B-red.svg)]()

## 🚀 Features

- **Unified API**: Same methods and events for both iOS and Android
- **Automatic Compliance**: Built-in GDPR, CCPA, and iOS ATT handling
- **Smart Ad Management**: Handles fresh ads (Android) vs reusable ads (iOS) automatically
- **Modern SDKs**: Uses latest Google Mobile Ads SDK (22.6.0+) and UMP SDK
- **Complete Ad Types**: Banner, Interstitial, Rewarded, App Open, and Adaptive Banner ads
- **TypeScript Ready**: Full TypeScript definitions included
- **Easy Migration**: Simple migration from existing ti.admob and ti.android.admob modules

## 📋 Requirements

- **Titanium SDK**: 12.8.0 or higher
- **iOS**: 12.0+ (Xcode 14+)
- **Android**: API Level 21+ (Android 5.0+)
- **Google Mobile Ads SDK**: 22.6.0+ (automatically included)

## 📦 Installation

### 1. Download the Module

Download the latest release from [GitHub Releases](https://github.com/macCesar/ti.admob.unified/releases)

### 2. Install Globally

Copy the `.zip` file to your Titanium modules directory:

- **macOS**: `~/Library/Application Support/Titanium/`
- **Windows**: `%APPDATA%\Titanium\`
- **Linux**: `~/.titanium/`

### 3. Add to Your Project

Edit your `tiapp.xml`:

```xml
<modules>
  <module>ti.admob.unified</module>
</modules>
```

### 4. Configure for Android

Add your AdMob App ID to `tiapp.xml`:

```xml
<android>
  <manifest>
    <application>
      <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
    </application>
  </manifest>
</android>
```

## 🎯 Quick Start

```javascript
const Admob = require('ti.admob.unified');

// 1. Initialize the SDK
Admob.initialize({
  applicationId: 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX', // Required for Android
  testDeviceIds: ['YOUR-TEST-DEVICE-ID'],
  debugGeography: Admob.DEBUG_GEOGRAPHY_EEA
});

// 2. Request consent (GDPR/CCPA/ATT)
Admob.requestConsent({
  geography: Admob.DEBUG_GEOGRAPHY_EEA,
  callback: function(result) {
    if (result.canShowAds) {
      setupAds();
    }
  }
});

// 3. Create and show ads
function setupAds() {
  const rewardedAd = Admob.createRewarded({
    autoReload: true,
    adUnitId: 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'
  });

  rewardedAd.addEventListener(Admob.AD_LOADED, () => {
    rewardedAd.show();
  });

  rewardedAd.addEventListener(Admob.AD_REWARDED, (e) => {
    console.log(`User earned ${e.rewardAmount} ${e.rewardType}`);
  });

  rewardedAd.load();
}
```

## 📚 API Reference

### Module Methods

#### `initialize(config)`

Initializes the Google Mobile Ads SDK.

**Parameters:**
- `config` (Object): Configuration options
  - `applicationId` (String): Your AdMob app ID (required for Android)
  - `testDeviceIds` (Array): Array of test device IDs
  - `debugGeography` (Number): Debug geography for consent testing
  - `tagForChildDirectedTreatment` (Boolean): COPPA compliance
  - `tagForUnderAgeOfConsent` (Boolean): GDPR under-age consent
  - `maxAdContentRating` (String): Maximum ad content rating

**Example:**
```javascript
Admob.initialize({
  tagForUnderAgeOfConsent: false,
  tagForChildDirectedTreatment: false,
  debugGeography: Admob.DEBUG_GEOGRAPHY_EEA,
  testDeviceIds: ['DEVICE-ID-1', 'DEVICE-ID-2'],
  applicationId: 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX',
  maxAdContentRating: Admob.MAX_AD_CONTENT_RATING_GENERAL
});
```

#### `requestConsent(config)`

Requests user consent for GDPR, CCPA, and other privacy regulations.

**Parameters:**
- `config` (Object): Consent configuration
  - `testDeviceIds` (Array): Test device IDs for consent debugging
  - `geography` (Number): Debug geography
  - `tagForUnderAgeOfConsent` (Boolean): Under age consent flag
  - `callback` (Function): Callback function with consent result

**Example:**
```javascript
Admob.requestConsent({
  testDeviceIds: ['YOUR-DEVICE-ID'],
  geography: Admob.DEBUG_GEOGRAPHY_EEA,
  callback: function(result) {
    console.log('Can show ads:', result.canShowAds);
    console.log('Can show personalized ads:', result.canShowPersonalizedAds);
    console.log('Is GDPR region:', result.isGDPR);
  }
});
```

#### `createRewarded(config)`

Creates a rewarded ad instance.

**Parameters:**
- `config` (Object): Ad configuration
  - `adUnitId` (String): AdMob ad unit ID
  - `autoReload` (Boolean): Automatically reload fresh ads (recommended: true)
  - `keywords` (Array): Targeting keywords
  - `extras` (Object): Additional parameters for mediation networks

**Returns:** RewardedAdProxy instance

**Example:**
```javascript
const rewardedAd = Admob.createRewarded({
  autoReload: true,
  extras: { 'npa': '1' }, // Disable personalized ads
  keywords: ['gaming', 'mobile'],
  adUnitId: 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',
});
```

#### `createInterstitial(config)`

Creates an interstitial ad instance.

**Parameters:**
- `config` (Object): Ad configuration (same as rewarded ads)

**Returns:** InterstitialAdProxy instance

#### `createBanner(config)`

Creates a banner ad instance.

**Parameters:**
- `config` (Object): Banner configuration
  - `adUnitId` (String): AdMob ad unit ID
  - `adSize` (String): Banner size (see Banner Sizes constants)
  - `backgroundColor` (String): Background color
  - All standard ad configuration options

**Returns:** BannerAdProxy instance

#### `createAdaptiveBanner(config)`

Creates an adaptive banner ad instance.

**Parameters:**
- `config` (Object): Adaptive banner configuration
  - `adUnitId` (String): AdMob ad unit ID
  - `adaptiveType` (String): Type of adaptive banner
  - `maxHeight` (Number): Maximum height for inline adaptive banners
  - All standard ad configuration options

**Returns:** BannerAdProxy instance

#### `createAppOpen(config)`

Creates an app open ad instance.

**Parameters:**
- `config` (Object): App open ad configuration
  - `adUnitId` (String): AdMob ad unit ID
  - `autoManage` (Boolean): Automatically manage 4-hour expiration
  - `minInterval` (Number): Minimum interval between shows (milliseconds)
  - All standard ad configuration options

**Returns:** AppOpenAdProxy instance

### Ad Proxy Methods

All ad proxy instances (Rewarded, Interstitial, Banner, AppOpen) support these methods:

#### `load()`

Loads the ad from the network.

#### `show()`

Shows the loaded ad (not applicable for banner ads).

#### `isLoaded()`

Returns whether the ad is loaded and ready to show.

**Returns:** Boolean

#### `destroy()`

Destroys the ad instance and frees memory.

### Consent Methods

#### `canShowAds()`

Checks if ads can be shown based on consent status.

**Returns:** Boolean

#### `canShowPersonalizedAds()`

Checks if personalized ads can be shown.

**Returns:** Boolean

#### `isGDPR()`

Checks if the user is in a GDPR region.

**Returns:** Boolean

#### `isPrivacyOptionsRequired()`

Checks if privacy options are required for the user.

**Returns:** Boolean

#### `presentPrivacyOptions(callback)`

Shows the privacy options form to the user.

#### `resetConsent()`

Resets consent information (for testing).

### iOS-Specific Methods

#### `requestTrackingAuthorization(config)`

Requests App Tracking Transparency authorization (iOS 14+).

**Parameters:**
  - `config` (Object): Configuration
  - `callback` (Function): Callback with authorization result

**Example:**
```javascript
Admob.requestTrackingAuthorization({
  callback: function(result) {
    console.log('Tracking authorization status:', result.status);
  }
});
```

### Utility Methods

#### `setAppVolume(volume)`

Sets the app volume for video ads.

**Parameters:**
- `volume` (String): Volume percentage (e.g., "50%")

#### `setTestDevice(deviceId)`

Sets a test device ID.

**Parameters:**
- `deviceId` (String): Device ID

#### `isTestDevice()`

Checks if the current device is configured as a test device.

**Returns:** Boolean

## 🎯 Constants

### Ad Types

```javascript
Admob.AD_TYPE_BANNER
Admob.AD_TYPE_INTERSTITIAL
Admob.AD_TYPE_REWARDED
Admob.AD_TYPE_REWARDED_INTERSTITIAL
Admob.AD_TYPE_APP_OPEN
Admob.AD_TYPE_NATIVE
```

### Banner Sizes

```javascript
Admob.BANNER               // 320x50
Admob.LARGE_BANNER         // 320x100
Admob.MEDIUM_RECTANGLE     // 300x250
Admob.FULLBANNER           // 468x60
Admob.LEADERBOARD          // 728x90
Admob.ADAPTIVE_ANCHORED
Admob.ADAPTIVE_INLINE
Admob.COLLAPSIBLE_TOP
Admob.COLLAPSIBLE_BOTTOM
```

### Events

```javascript
// Loading Events
Admob.AD_LOADED
Admob.AD_FAILED_TO_LOAD

// Interaction Events
Admob.AD_OPENED
Admob.AD_CLOSED
Admob.AD_CLICKED
Admob.AD_IMPRESSION

// Reward Events
Admob.AD_REWARDED

// Error Events
Admob.AD_FAILED_TO_SHOW
```

### Consent Status

```javascript
Admob.CONSENT_STATUS_UNKNOWN
Admob.CONSENT_STATUS_REQUIRED
Admob.CONSENT_STATUS_NOT_REQUIRED
Admob.CONSENT_STATUS_OBTAINED
```

### Debug Geography

```javascript
Admob.DEBUG_GEOGRAPHY_DISABLED
Admob.DEBUG_GEOGRAPHY_EEA                // Europe (GDPR)
Admob.DEBUG_GEOGRAPHY_REGULATED_US_STATE // Regulated US states
Admob.DEBUG_GEOGRAPHY_OTHER
```

### iOS Tracking Authorization

```javascript
Admob.TRACKING_AUTHORIZATION_STATUS_NOT_DETERMINED
Admob.TRACKING_AUTHORIZATION_STATUS_RESTRICTED
Admob.TRACKING_AUTHORIZATION_STATUS_DENIED
Admob.TRACKING_AUTHORIZATION_STATUS_AUTHORIZED
```

### Content Rating

```javascript
Admob.MAX_AD_CONTENT_RATING_GENERAL
Admob.MAX_AD_CONTENT_RATING_PARENTAL_GUIDANCE
Admob.MAX_AD_CONTENT_RATING_TEEN
Admob.MAX_AD_CONTENT_RATING_MATURE_AUDIENCE
```

### Error Codes

```javascript
Admob.ERROR_CODE_NETWORK_ERROR       // 2
Admob.ERROR_CODE_NO_FILL             // 3
Admob.ERROR_CODE_INVALID_REQUEST     // 1
Admob.ERROR_CODE_SERVER_ERROR        // 0
Admob.ERROR_CODE_APP_ID_MISSING      // 8
```

## 📱 Event Handling

### Rewarded Ad Events

```javascript
const rewardedAd = Admob.createRewarded({
  autoReload: true,
  adUnitId: 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'
});

// Ad loaded successfully
rewardedAd.addEventListener(Admob.AD_LOADED, function(e) {
  console.log('Ad loaded:', e.adUnitId);
});

// Ad failed to load
rewardedAd.addEventListener(Admob.AD_FAILED_TO_LOAD, function(e) {
  console.error('Ad failed to load:', e.error);
  console.error('Error code:', e.code);
});

// User earned reward
rewardedAd.addEventListener(Admob.AD_REWARDED, function(e) {
  console.log('User earned reward!');
  console.log('Type:', e.rewardType);      // e.g., "coins"
  console.log('Amount:', e.rewardAmount);  // e.g., 10

  // Grant reward to user
  grantUserReward(e.rewardType, e.rewardAmount);
});

// Ad was closed
rewardedAd.addEventListener(Admob.AD_CLOSED, function(e) {
  console.log('Ad closed');
  // autoReload handles loading the next ad automatically
});

// Ad failed to show
rewardedAd.addEventListener(Admob.AD_FAILED_TO_SHOW, function(e) {
  console.error('Failed to show ad:', e.error);
});

// Ad impression recorded
rewardedAd.addEventListener(Admob.AD_IMPRESSION, function(e) {
  console.log('Ad impression recorded');
});

// Ad was clicked
rewardedAd.addEventListener(Admob.AD_CLICKED, function(e) {
  console.log('Ad was clicked');
});
```

### Module Events

```javascript
// SDK initialization completed
Admob.addEventListener('module_initialized', function(e) {
  console.log('AdMob SDK initialized successfully');
});

// Consent process completed
Admob.addEventListener('consent_ready', function(e) {
  console.log('Consent ready');
  console.log('Can show ads:', e.canShowAds);
  console.log('Can show personalized ads:', e.canShowPersonalizedAds);
  console.log('Is GDPR region:', e.isGDPR);
});

// Consent error occurred
Admob.addEventListener('consent_error', function(e) {
  console.error('Consent error:', e.error);
});

// iOS tracking authorization completed
Admob.addEventListener('tracking_authorization_completed', function(e) {
  console.log('Tracking authorization status:', e.status);
});
```

## 🧪 Test Ad Unit IDs

Use these official Google test ad unit IDs during development:

```javascript
const TEST_AD_UNITS = {
  BANNER: 'ca-app-pub-3940256099942544/6300978111',
  ADAPTIVE_BANNER: 'ca-app-pub-3940256099942544/9214589741',
  INTERSTITIAL: 'ca-app-pub-3940256099942544/1033173712',
  INTERSTITIAL_VIDEO: 'ca-app-pub-3940256099942544/8691691433',
  REWARDED: 'ca-app-pub-3940256099942544/5224354917',
  REWARDED_INTERSTITIAL: 'ca-app-pub-3940256099942544/5354046379',
  NATIVE: 'ca-app-pub-3940256099942544/2247696110',
  APP_OPEN: 'ca-app-pub-3940256099942544/9257395921'
};

// Helper function to get appropriate ad unit ID
function getAdUnitId(adType) {
  return Ti.App.deployType === 'production'
    ? 'ca-app-pub-YOUR-REAL-ID/YOUR-REAL-UNIT'
    : TEST_AD_UNITS[adType];
}
```

## 🔄 Migration Guide

### From ti.admob + ti.android.admob

If you're currently using separate modules for iOS and Android:

#### Before (Platform-specific code):
```javascript
let Admob;
if (OS_IOS) {
  Admob = require('ti.admob');
} else {
  Admob = require('ti.android.admob');
}

// Platform-specific ad creation
let rewardedAd;
if (OS_IOS) {
  rewardedAd = Admob.createView({
    adUnitId: adUnitId,
    adType: Admob.AD_TYPE_REWARDED_VIDEO
  });
  rewardedAd.addEventListener('didRewardUser', handleReward);
} else {
  rewardedAd = Admob.createRewarded({
    adUnitId: adUnitId,
    adSizeType: Admob.REWARDED
  });
  rewardedAd.addEventListener(Admob.AD_REWARDED, handleReward);
}
```

#### After (Unified code):
```javascript
const Admob = require('ti.admob.unified');

// Unified ad creation
const rewardedAd = Admob.createRewarded({
  autoReload: true,
  adUnitId: adUnitId
});

// Unified event handling
rewardedAd.addEventListener(Admob.AD_REWARDED, handleReward);
```

### Update tiapp.xml

#### Before:
```xml
<modules>
  <module platform="iphone">ti.admob</module>
  <module platform="android">ti.android.admob</module>
</modules>
```

#### After:
```xml
<modules>
  <module>ti.admob.unified</module>
</modules>
```

## 🏗️ Building

### Prerequisites

- Titanium SDK 12.8.0+
- Xcode 14+ (for iOS)
- Android SDK with API 21+ (for Android)

### Build Commands

```bash
# Build for iOS
ti build -p ios --build-only

# Build for Android
ti build -p android --build-only

# Build for both platforms
ti build -p ios --build-only && ti build -p android --build-only
```

### Development Setup

1. Clone the repository
2. Install dependencies (handled automatically by Titanium)
3. Build the module using the commands above
4. Test with the example app: `ti build -p [ios|android]`

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Add tests if applicable
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Code Style

- Follow existing code style and conventions
- Add JSDoc comments for all public methods
- Include TypeScript definitions for new APIs
- Test on both iOS and Android platforms

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Google AdMob team for the excellent mobile ads platform
- Titanium SDK community for the robust mobile development framework
- [Astrovic (Vittorio Sorbera)](https://github.com/Astrovic) for inspiration from the original ti.admob improvements

## 📞 Support

- 📧 Email: [support@codigomovil.mx](mailto:support@codigomovil.mx)
- 🐛 Issues: [GitHub Issues](https://github.com/macCesar/ti.admob.unified/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/macCesar/ti.admob.unified/discussions)

## 🔗 Links

- [Google AdMob](https://admob.google.com/)
- [Titanium SDK](https://titaniumsdk.com/)
- [Google Mobile Ads SDK](https://developers.google.com/admob/android/sdk)
- [User Messaging Platform](https://developers.google.com/admob/ump)
