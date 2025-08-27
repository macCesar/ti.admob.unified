/**
 * ti.admob.unified - Example App
 * Unified AdMob Module for Titanium SDK
 * Copyright (c) 2025 César Estrada
 * 
 * This example demonstrates how to use the ti.admob.unified module
 * with all supported ad types and compliance features.
 */

// Import the unified AdMob module
var Admob = require('ti.admob.unified');
Ti.API.info("AdMob Unified Module loaded: " + Admob);

// Test Ad Unit IDs (Google's official test IDs)
var TEST_IDS = {
  BANNER: 'ca-app-pub-3940256099942544/6300978111',
  INTERSTITIAL: 'ca-app-pub-3940256099942544/1033173712',
  REWARDED: 'ca-app-pub-3940256099942544/5224354917',
  APP_OPEN: 'ca-app-pub-3940256099942544/9257395921'
};

// Helper function to get ad unit ID based on environment
function getAdUnitId(adType) {
  // Always use test IDs in this example
  return TEST_IDS[adType];
}

// Global ad references
var rewardedAd;
var interstitialAd;
var bannerAd;

// Create main window
var win = Ti.UI.createWindow({
  backgroundColor: '#f0f0f0',
  title: 'AdMob Unified Example'
});

// Create UI elements
var scrollView = Ti.UI.createScrollView({
  layout: 'vertical',
  top: 0,
  width: Ti.UI.FILL,
  height: Ti.UI.FILL,
  showVerticalScrollIndicator: true
});

// Status label
var statusLabel = Ti.UI.createLabel({
  text: 'AdMob Unified - Initializing...',
  top: 20,
  left: 20,
  right: 20,
  height: Ti.UI.SIZE,
  color: '#333',
  font: { fontSize: 16 },
  textAlign: 'center'
});

// Info label about mediation
var infoLabel = Ti.UI.createLabel({
  text: '💡 This module includes mediation adapters for Facebook, InMobi, Unity, AppLovin, and more to maximize your ad revenue!',
  top: 10,
  left: 20,
  right: 20,
  height: Ti.UI.SIZE,
  color: '#666',
  font: { fontSize: 12 },
  textAlign: 'center'
});

// Buttons container
var buttonsContainer = Ti.UI.createView({
  layout: 'vertical',
  top: 20,
  left: 20,
  right: 20,
  height: Ti.UI.SIZE
});

// Helper function to create buttons
function createButton(title, handler) {
  var button = Ti.UI.createButton({
    title: title,
    top: 10,
    height: 50,
    backgroundColor: '#4CAF50',
    color: 'white',
    font: { fontSize: 16, fontWeight: 'bold' },
    borderRadius: 8
  });
  button.addEventListener('click', handler);
  return button;
}

// Initialize button
var initButton = createButton('1. Initialize AdMob', function () {
  statusLabel.text = 'Initializing Google Mobile Ads SDK...';

  Admob.initialize({
    applicationId: 'ca-app-pub-3940256099942544~3347511713', // Test app ID
    testDeviceIds: ['33BE2250B43518CCDA7DE426D04EE231'], // Add your device ID here - check logcat for "This request is sent from a test device"
    debugGeography: Admob.DEBUG_GEOGRAPHY_EEA,
    tagForChildDirectedTreatment: false,
    tagForUnderAgeOfConsent: false,
    maxAdContentRating: Admob.MAX_AD_CONTENT_RATING_GENERAL
  });
});

// Request consent button
var consentButton = createButton('2. Request Consent (GDPR)', function () {
  statusLabel.text = 'Requesting consent...';

  Admob.requestConsent({
    testDeviceIds: ['DEVICE-ID-HERE'],
    geography: Admob.DEBUG_GEOGRAPHY_EEA,
    tagForUnderAgeOfConsent: false,
    callback: function (result) {
      statusLabel.text = 'Consent: ' + (result.canShowAds ? 'Granted' : 'Denied');
      Ti.API.info('Consent result: ' + JSON.stringify(result));
    }
  });
});

// Create rewarded ad button
var createRewardedButton = createButton('3. Create Rewarded Ad', function () {
  statusLabel.text = 'Creating rewarded ad...';

  rewardedAd = Admob.createRewarded({
    adUnitId: getAdUnitId('REWARDED'),
    autoReload: true
  });

  // Set up event listeners
  rewardedAd.addEventListener(Admob.AD_LOADED, function (e) {
    statusLabel.text = 'Rewarded ad loaded successfully!';
    Ti.API.info('Rewarded ad loaded: ' + e.adUnitId);
  });

  rewardedAd.addEventListener(Admob.AD_FAILED_TO_LOAD, function (e) {
    statusLabel.text = 'Rewarded ad failed to load: ' + e.error;
    Ti.API.error('Rewarded ad error: ' + e.error);
  });

  rewardedAd.addEventListener(Admob.AD_REWARDED, function (e) {
    statusLabel.text = 'User earned reward: ' + e.rewardAmount + ' ' + e.rewardType;
    Ti.API.info('User rewarded: ' + JSON.stringify(e));
  });

  rewardedAd.addEventListener(Admob.AD_CLOSED, function (e) {
    statusLabel.text = 'Rewarded ad closed';
    Ti.API.info('Rewarded ad closed');
  });

  // Load the ad
  rewardedAd.load();
});

// Show rewarded ad button
var showRewardedButton = createButton('4. Show Rewarded Ad', function () {
  if (rewardedAd && rewardedAd.isLoaded()) {
    statusLabel.text = 'Showing rewarded ad...';
    rewardedAd.show();
  } else {
    statusLabel.text = 'Rewarded ad not ready. Create and load first.';
  }
});

// Create interstitial ad button
var createInterstitialButton = createButton('5. Create Interstitial Ad', function () {
  statusLabel.text = 'Creating interstitial ad...';

  interstitialAd = Admob.createInterstitial({
    adUnitId: getAdUnitId('INTERSTITIAL'),
    autoReload: true
  });

  // Set up event listeners
  interstitialAd.addEventListener(Admob.AD_LOADED, function (e) {
    statusLabel.text = 'Interstitial ad loaded successfully!';
  });

  interstitialAd.addEventListener(Admob.AD_FAILED_TO_LOAD, function (e) {
    statusLabel.text = 'Interstitial ad failed to load: ' + e.error;
  });

  interstitialAd.addEventListener(Admob.AD_CLOSED, function (e) {
    statusLabel.text = 'Interstitial ad closed';
  });

  // Load the ad
  interstitialAd.load();
});

// Show interstitial ad button
var showInterstitialButton = createButton('6. Show Interstitial Ad', function () {
  if (interstitialAd && interstitialAd.isLoaded()) {
    statusLabel.text = 'Showing interstitial ad...';
    interstitialAd.show();
  } else {
    statusLabel.text = 'Interstitial ad not ready. Create and load first.';
  }
});

// Create banner ad button
var createBannerButton = createButton('7. Create Banner Ad', function () {
  if (bannerAd) {
    // Remove existing banner
    scrollView.remove(bannerAd);
  }

  statusLabel.text = 'Creating banner ad...';

  bannerAd = Admob.createBanner({
    adUnitId: Admob.TEST_BANNER,
    adSize: Admob.BANNER,
    width: Ti.UI.FILL,
    height: 60
  });

  // Set up event listeners
  bannerAd.addEventListener(Admob.AD_LOADED, function (e) {
    statusLabel.text = 'Banner ad loaded successfully!';
  });

  bannerAd.addEventListener(Admob.AD_FAILED_TO_LOAD, function (e) {
    statusLabel.text = 'Banner ad failed to load: ' + e.error;
  });

  bannerAd.addEventListener(Admob.AD_CLICKED, function (e) {
    statusLabel.text = 'Banner ad clicked!';
  });

  // Add banner to scroll view
  scrollView.add(bannerAd);
  
  // Load the banner ad
  bannerAd.load();
});

// Module event listeners
Admob.addEventListener('module_initialized', function (e) {
  statusLabel.text = 'AdMob SDK initialized successfully!';
  Ti.API.info('AdMob SDK initialized');
});

Admob.addEventListener('consent_ready', function (e) {
  statusLabel.text = 'Consent ready - Can show ads: ' + e.canShowAds;
  Ti.API.info('Consent ready: ' + JSON.stringify(e));
});

Admob.addEventListener('consent_error', function (e) {
  statusLabel.text = 'Consent error: ' + e.error;
  Ti.API.error('Consent error: ' + e.error);
});

// Add all UI elements
buttonsContainer.add(initButton);
buttonsContainer.add(consentButton);
buttonsContainer.add(createRewardedButton);
buttonsContainer.add(showRewardedButton);
buttonsContainer.add(createInterstitialButton);
buttonsContainer.add(showInterstitialButton);
buttonsContainer.add(createBannerButton);

scrollView.add(statusLabel);
scrollView.add(infoLabel);
scrollView.add(buttonsContainer);

win.add(scrollView);

// iOS specific: Request tracking authorization
if (Ti.Platform.osname === 'iphone' || Ti.Platform.osname === 'ipad') {
  Admob.requestTrackingAuthorization({
    callback: function (result) {
      Ti.API.info('Tracking authorization: ' + result.status);
    }
  });
}

// Handle app lifecycle for better ad management
Ti.App.addEventListener('resumed', function () {
  Ti.API.info('App resumed - checking ad readiness');
  if (rewardedAd && !rewardedAd.isLoaded()) {
    rewardedAd.load();
  }
  if (interstitialAd && !interstitialAd.isLoaded()) {
    interstitialAd.load();
  }
});

// Open the window
win.open();
