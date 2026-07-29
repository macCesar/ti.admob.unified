# Getting started

## 1. Install the module

Install the `1.2.0` ZIP for every platform you build. Both artifacts must have
the same module ID and version:

```xml
<modules>
  <module version="1.2.0">ti.admob.unified</module>
</modules>
```

The current baselines are Titanium `13.4.0.GA`, iOS `15.0+`, and Android API
`23+`.

## 2. Configure the AdMob application IDs

An AdMob **application ID** contains a tilde:

```text
ca-app-pub-0000000000000000~0000000000
```

An **ad unit ID** contains a slash:

```text
ca-app-pub-0000000000000000/0000000000
```

They are not interchangeable. The application ID belongs in `tiapp.xml`; ad
unit IDs are supplied to ad factories such as `createAdaptiveBanner()`.

### iOS

Add the iOS application ID to the app plist section:

```xml
<ios>
  <plist>
    <dict>
      <key>GADApplicationIdentifier</key>
      <string>ca-app-pub-0000000000000000~0000000000</string>
    </dict>
  </plist>
</ios>
```

For App Tracking Transparency, also add a clear, app-specific usage
description:

```xml
<ios>
  <plist>
    <dict>
      <key>NSUserTrackingUsageDescription</key>
      <string>This identifier helps us measure advertising performance.</string>
    </dict>
  </plist>
</ios>
```

Keep any required `SKAdNetworkItems` in the consuming app. Follow Google's
[iOS setup guide](https://developers.google.com/admob/ios/quick-start) for the
current list and App Store requirements.

### Android

Merge the Android application ID into the application element:

```xml
<android xmlns:android="http://schemas.android.com/apk/res/android">
  <manifest>
    <application>
      <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="ca-app-pub-0000000000000000~0000000000"/>
    </application>
  </manifest>
</android>
```

Omitting this metadata causes the native Google Mobile Ads SDK to fail with a
missing application ID. See Google's
[Android setup guide](https://developers.google.com/admob/android/quick-start).

Do not pass `applicationId` to `initialize()`; the module does not consume
that property.

## 3. Configure Privacy & messaging

Create the required messages in the **Privacy & messaging** section of the
AdMob console. UMP resolves the message configuration from the application ID
in the consuming app.

The application must request a fresh consent-information update on every
launch. See [Privacy and initialization](privacy.md) before loading any ad.

## 4. Use official test units

The `TEST_*` constants resolve to Google's platform-specific demo ad unit IDs:

```js
const Admob = require('ti.admob.unified')

const adaptiveId = Admob.TEST_ADAPTIVE_BANNER
const interstitialId = Admob.TEST_INTERSTITIAL
const rewardedId = Admob.TEST_REWARDED
```

Do not copy an Android demo ID into an iOS branch or the reverse. Let the
module constant select the correct ID.

Google recommends demo units or explicitly registered test devices during
development. See the official
[Android test-ad guide](https://developers.google.com/admob/android/test-ads)
and [iOS test-ad guide](https://developers.google.com/admob/ios/test-ads).

## 5. Request consent, then initialize

Register all listeners first:

```js
const Admob = require('ti.admob.unified')

let initialized = false

function initializeOnce() {
  if (initialized || !Admob.canRequestAds()) {
    return
  }

  initialized = true
  Admob.initialize({
    ageRestrictedTreatment: Admob.AGE_RESTRICTED_TREATMENT_UNSPECIFIED,
    maxAdContentRating: Admob.MAX_AD_CONTENT_RATING_GENERAL
  })
}

Admob.addEventListener('module_initialized', event => {
  if (event.success) {
    Ti.API.info('Google Mobile Ads initialized')
  } else {
    Ti.API.warn(`Google Mobile Ads initialization failed: ${event.error}`)
  }
})

Admob.addEventListener('consent_complete', event => {
  if (!event.canRequestAds) {
    return
  }

  const onTrackingComplete = trackingEvent => {
    Admob.removeEventListener(
      'tracking_authorization_completed',
      onTrackingComplete
    )
    Ti.API.info(`ATT status: ${trackingEvent.status}`)
    initializeOnce()
  }

  Admob.addEventListener(
    'tracking_authorization_completed',
    onTrackingComplete
  )
  Admob.requestTrackingAuthorization()
})

Admob.requestConsent({
  tagForUnderAgeOfConsent: false
})
```

`initialize()` and `requestConsent()` are idempotent native operations.
Application-level guards are still useful because cached terminal events may
be emitted again when a caller invokes an already-completed operation.

## 6. Create an ad only after the gate opens

```js
if (Admob.canRequestAds()) {
  const banner = Admob.createAdaptiveBanner({
    adUnitId: Admob.TEST_ADAPTIVE_BANNER,
    adaptiveType: Admob.ADAPTIVE_ANCHORED,
    width: Ti.UI.FILL
  })

  bannerHost.add(banner)
  banner.load()
}
```

The module does not enforce the privacy gate inside ad proxies. The consuming
application owns the order.

## Common setup mistakes

- Passing an ad unit ID where an application ID is required.
- Passing `applicationId` or `debugGeography` to `initialize()`.
- Loading ads before `consent_complete` and `canRequestAds === true`.
- Using `canShowPersonalizedAds()` or `isGDPR()` as a gate.
- Hardcoding an adaptive banner height.
- Keeping banner listeners after destroying or removing a placement.
- Using a production ad unit while clicking ads during development.
