/**
 * ti.admob.unified - Unified AdMob Module for Titanium SDK
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 *
 */
package ti.admob.unified;

import android.app.Activity;
import android.content.SharedPreferences;

import com.google.android.gms.ads.*;
import com.google.android.gms.ads.initialization.InitializationStatus;
import com.google.android.gms.ads.initialization.OnInitializationCompleteListener;
import com.google.android.ump.*;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.KrollModule;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.kroll.common.Log;
import org.appcelerator.kroll.common.TiConfig;
import org.appcelerator.titanium.TiApplication;

import java.util.Arrays;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;


@Kroll.module(name="TiAdmobUnified", id="ti.admob.unified")
public class TiAdmobUnifiedModule extends KrollModule
{
	// Standard Debugging variables
	private static final String LCAT = "TiAdmobUnifiedModule";
	private static final boolean DBG = TiConfig.LOGD;

	// ===================================================================
	// AD TYPE CONSTANTS
	// ===================================================================
	@Kroll.constant public static final String AD_TYPE_BANNER = "banner";
	@Kroll.constant public static final String AD_TYPE_INTERSTITIAL = "interstitial";
	@Kroll.constant public static final String AD_TYPE_REWARDED = "rewarded";
	@Kroll.constant public static final String AD_TYPE_REWARDED_INTERSTITIAL = "rewarded_interstitial";
	@Kroll.constant public static final String AD_TYPE_APP_OPEN = "app_open";
	@Kroll.constant public static final String AD_TYPE_NATIVE = "native";

	// ===================================================================
	// BANNER SIZE CONSTANTS
	// ===================================================================
	@Kroll.constant public static final String BANNER = "banner";
	@Kroll.constant public static final String LARGE_BANNER = "large_banner";
	@Kroll.constant public static final String MEDIUM_RECTANGLE = "medium_rectangle";
	@Kroll.constant public static final String FULLBANNER = "fullbanner";
	@Kroll.constant public static final String LEADERBOARD = "leaderboard";
	@Kroll.constant public static final String ADAPTIVE_ANCHORED = "adaptive_anchored";
	@Kroll.constant public static final String ADAPTIVE_INLINE = "adaptive_inline";
	@Kroll.constant public static final String COLLAPSIBLE_TOP = "collapsible_top";
	@Kroll.constant public static final String COLLAPSIBLE_BOTTOM = "collapsible_bottom";

	// ===================================================================
	// EVENT CONSTANTS (UNIFIED NAMING)
	// ===================================================================
	@Kroll.constant public static final String AD_LOADED = "loaded";
	@Kroll.constant public static final String AD_FAILED_TO_LOAD = "failed_to_load";
	@Kroll.constant public static final String AD_OPENED = "opened";
	@Kroll.constant public static final String AD_CLOSED = "closed";
	@Kroll.constant public static final String AD_CLICKED = "clicked";
	@Kroll.constant public static final String AD_IMPRESSION = "impression";
	@Kroll.constant public static final String AD_REWARDED = "rewarded";
	@Kroll.constant public static final String AD_FAILED_TO_SHOW = "failed_to_show";
	@Kroll.constant public static final String AD_SHOWED_FULLSCREEN_CONTENT = "showed_fullscreen_content";
	@Kroll.constant public static final String AD_DESTROYED = "destroyed";

	// ===================================================================
	// CONSENT/COMPLIANCE CONSTANTS
	// ===================================================================
	@Kroll.constant public static final int CONSENT_STATUS_UNKNOWN = ConsentInformation.ConsentStatus.UNKNOWN;
	@Kroll.constant public static final int CONSENT_STATUS_REQUIRED = ConsentInformation.ConsentStatus.REQUIRED;
	@Kroll.constant public static final int CONSENT_STATUS_NOT_REQUIRED = ConsentInformation.ConsentStatus.NOT_REQUIRED;
	@Kroll.constant public static final int CONSENT_STATUS_OBTAINED = ConsentInformation.ConsentStatus.OBTAINED;

	// Note: FormStatus constants removed as ConsentInformation.FormStatus is not available in current UMP SDK
	// Use isConsentFormAvailable() method instead

	// Debug Geography Constants
	@Kroll.constant public static final int DEBUG_GEOGRAPHY_DISABLED = ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_DISABLED;
	@Kroll.constant public static final int DEBUG_GEOGRAPHY_EEA = ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_EEA;
	// Using non-deprecated constants for US states and other regions
	@Kroll.constant public static final int DEBUG_GEOGRAPHY_REGULATED_US_STATE = ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_REGULATED_US_STATE;
	@Kroll.constant public static final int DEBUG_GEOGRAPHY_OTHER = ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_OTHER;

	// Content Rating Constants
	@Kroll.constant public static final String MAX_AD_CONTENT_RATING_GENERAL = "G";
	@Kroll.constant public static final String MAX_AD_CONTENT_RATING_PARENTAL_GUIDANCE = "PG";
	@Kroll.constant public static final String MAX_AD_CONTENT_RATING_TEEN = "T";
	@Kroll.constant public static final String MAX_AD_CONTENT_RATING_MATURE_AUDIENCE = "MA";

	// ===================================================================
	// ERROR CODE CONSTANTS
	// ===================================================================
	@Kroll.constant public static final int ERROR_CODE_NETWORK_ERROR = 2;
	@Kroll.constant public static final int ERROR_CODE_NO_FILL = 3;
	@Kroll.constant public static final int ERROR_CODE_INVALID_REQUEST = 1;
	@Kroll.constant public static final int ERROR_CODE_SERVER_ERROR = 0;
	@Kroll.constant public static final int ERROR_CODE_APP_ID_MISSING = 8;
	@Kroll.constant public static final int ERROR_CODE_MEDIATION_NO_FILL = 9;
	@Kroll.constant public static final int ERROR_CODE_INVALID_AD_SIZE = 10;

	// ===================================================================
	// TEST AD UNIT IDS (OFFICIAL GOOGLE TEST IDS)
	// ===================================================================
	@Kroll.constant public static final String TEST_BANNER = "ca-app-pub-3940256099942544/6300978111";
	@Kroll.constant public static final String TEST_ADAPTIVE_BANNER = "ca-app-pub-3940256099942544/9214589741";
	@Kroll.constant public static final String TEST_INTERSTITIAL = "ca-app-pub-3940256099942544/1033173712";
	@Kroll.constant public static final String TEST_INTERSTITIAL_VIDEO = "ca-app-pub-3940256099942544/8691691433";
	@Kroll.constant public static final String TEST_REWARDED = "ca-app-pub-3940256099942544/5224354917";
	@Kroll.constant public static final String TEST_REWARDED_INTERSTITIAL = "ca-app-pub-3940256099942544/5354046379";
	@Kroll.constant public static final String TEST_NATIVE = "ca-app-pub-3940256099942544/2247696110";
	@Kroll.constant public static final String TEST_APP_OPEN = "ca-app-pub-3940256099942544/9257395921";

	// ===================================================================
	// MODULE LIFECYCLE
	// ===================================================================
	public TiAdmobUnifiedModule()
	{
		super();
	}

	@Kroll.onAppCreate
	public static void onAppCreate(TiApplication app)
	{
		Log.d(LCAT, "TiAdmobUnified module initialized");
	}

	// ===================================================================
	// SDK INITIALIZATION METHODS
	// ===================================================================
	@Kroll.method
	public void initialize(KrollDict config)
	{
		Log.d(LCAT, "Initializing Google Mobile Ads SDK");
		
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			Log.e(LCAT, "Cannot initialize - no current activity");
			return;
		}

		// Configure request configuration if provided
		if (config != null) {
			RequestConfiguration.Builder requestConfigBuilder = new RequestConfiguration.Builder();
			
			// Test device IDs
			if (config.containsKey("testDeviceIds")) {
				String[] testDeviceIds = config.getStringArray("testDeviceIds");
				if (testDeviceIds != null && testDeviceIds.length > 0) {
					Log.d(LCAT, "Setting test device IDs: " + Arrays.toString(testDeviceIds));
					requestConfigBuilder.setTestDeviceIds(Arrays.asList(testDeviceIds));
				}
			}
			
			// COPPA + GDPR <16. Google's docs reference setAgeRestrictedTreatment as the
			// future replacement but it's not yet shipped in play-services-ads 25.3.0.
			// Keep deprecated TFCD/TFUA setters until the consolidated API ships.
			setAgeRestrictionsLegacy(requestConfigBuilder, config);
			
			// Max ad content rating
			if (config.containsKey("maxAdContentRating")) {
				String rating = config.getString("maxAdContentRating");
				requestConfigBuilder.setMaxAdContentRating(rating);
			}
			
			MobileAds.setRequestConfiguration(requestConfigBuilder.build());
		}

		// Initialize the SDK with FAST initialization (no problematic adapters)
		Log.d(LCAT, "Starting FAST AdMob SDK initialization...");
		
		MobileAds.initialize(activity, new OnInitializationCompleteListener() {
			@Override
			public void onInitializationComplete(InitializationStatus initializationStatus) {
				Log.d(LCAT, "AdMob SDK initialization completed successfully");
				
				// Log adapter statuses for debugging
				Map<String, com.google.android.gms.ads.initialization.AdapterStatus> statusMap = 
					initializationStatus.getAdapterStatusMap();
				for (String adapterClass : statusMap.keySet()) {
					com.google.android.gms.ads.initialization.AdapterStatus status = statusMap.get(adapterClass);
					Log.d(LCAT, String.format("Adapter %s: %s", adapterClass, status.getDescription()));
				}
				
				// Fire module initialization event
				Map<String, Object> event = new HashMap<>();
				event.put("success", true);
				event.put("status", initializationStatus.toString());
				fireEvent("module_initialized", event);
			}
		});
	}

	@SuppressWarnings("deprecation") // TFCD/TFUA setters are deprecated in GMA 25.x;
	// kept in place until setAgeRestrictedTreatment(AgeRestrictedTreatment) ships in a future SDK.
	private void setAgeRestrictionsLegacy(RequestConfiguration.Builder builder, KrollDict config)
	{
		if (config.containsKey("tagForChildDirectedTreatment")) {
			boolean childDirected = config.getBoolean("tagForChildDirectedTreatment");
			builder.setTagForChildDirectedTreatment(
				childDirected ? RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_TRUE
							 : RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_FALSE);
		}
		if (config.containsKey("tagForUnderAgeOfConsent")) {
			boolean underAge = config.getBoolean("tagForUnderAgeOfConsent");
			builder.setTagForUnderAgeOfConsent(
				underAge ? RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_TRUE
						 : RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_FALSE);
		}
	}

	// ===================================================================
	// MEDIATION NETWORK CONFIGURATION METHODS
	// ===================================================================
	@Kroll.method
	public void setAppLovinGDPRConsent(KrollDict config)
	{
		if (config != null && config.containsKey("enabled")) {
			boolean isEnabled = config.getBoolean("enabled");
			Log.d(LCAT, "Setting AppLovin GDPR consent: " + isEnabled);
			
			try {
				// Only initialize AppLovin if the SDK is available
				Class<?> appLovinPrivacyClass = Class.forName("com.applovin.sdk.AppLovinPrivacySettings");
				
				// Use reflection to avoid compile-time dependency
				java.lang.reflect.Method setHasUserConsentMethod = 
					appLovinPrivacyClass.getDeclaredMethod("setHasUserConsent", boolean.class, android.content.Context.class);
				java.lang.reflect.Method setDoNotSellMethod = 
					appLovinPrivacyClass.getDeclaredMethod("setDoNotSell", boolean.class, android.content.Context.class);
				
				Activity activity = TiApplication.getInstance().getCurrentActivity();
				if (activity != null) {
					// EU consent and GDPR
					setHasUserConsentMethod.invoke(null, isEnabled, activity);
					// CCPA - Do Not Sell is inverse of consent
					setDoNotSellMethod.invoke(null, !isEnabled, activity);
					
					Log.d(LCAT, "AppLovin GDPR consent configured successfully");
				}
				
			} catch (ClassNotFoundException e) {
				Log.w(LCAT, "AppLovin SDK not available, skipping GDPR configuration");
			} catch (Exception e) {
				Log.e(LCAT, "Error configuring AppLovin GDPR consent: " + e.getMessage());
			}
		}
	}

	@Kroll.method
	public void setInMobiGDPRConsent(KrollDict config)
	{
		if (config != null && config.containsKey("enabled")) {
			boolean isEnabled = config.getBoolean("enabled");
			Log.d(LCAT, "Setting InMobi GDPR consent: " + isEnabled);
			
			try {
				// Only initialize InMobi if the SDK is available
				Class<?> inMobiSdkClass = Class.forName("com.inmobi.sdk.InMobiSdk");
				Class<?> inMobiConsentClass = Class.forName("com.google.ads.mediation.inmobi.InMobiConsent");
				
				// Get IM_GDPR_CONSENT_AVAILABLE constant
				String IM_GDPR_CONSENT_AVAILABLE = (String) inMobiSdkClass.getField("IM_GDPR_CONSENT_AVAILABLE").get(null);
				
				// Create consent JSON object
				org.json.JSONObject consentObject = new org.json.JSONObject();
				consentObject.put(IM_GDPR_CONSENT_AVAILABLE, true);
				consentObject.put("gdpr", isEnabled ? "1" : "0");
				
				// Update GDPR consent
				java.lang.reflect.Method updateGDPRConsentMethod = 
					inMobiConsentClass.getDeclaredMethod("updateGDPRConsent", org.json.JSONObject.class);
				updateGDPRConsentMethod.invoke(null, consentObject);
				
				Log.d(LCAT, "InMobi GDPR consent configured successfully");
				
			} catch (ClassNotFoundException e) {
				Log.w(LCAT, "InMobi SDK not available, skipping GDPR configuration");
			} catch (Exception e) {
				Log.e(LCAT, "Error configuring InMobi GDPR consent: " + e.getMessage());
			}
		}
	}

	@Kroll.method
	public void setVungleGDPRConsent(KrollDict config)
	{
		if (config != null && config.containsKey("enabled")) {
			boolean isEnabled = config.getBoolean("enabled");
			Log.d(LCAT, "Setting Vungle GDPR consent: " + isEnabled);
			
			try {
				// Only configure Vungle if the SDK is available
				Class<?> vunglePrivacyClass = Class.forName("com.vungle.warren.VunglePrivacySettings");
				
				// Set GDPR consent status
				java.lang.reflect.Method setGDPRStatusMethod = 
					vunglePrivacyClass.getDeclaredMethod("setGDPRStatus", boolean.class, String.class);
				
				// Set CCPA status  
				java.lang.reflect.Method setCCPAStatusMethod = 
					vunglePrivacyClass.getDeclaredMethod("setCCPAStatus", boolean.class);
				
				// Configure GDPR
				setGDPRStatusMethod.invoke(null, true, isEnabled ? "opted_in" : "opted_out");
				// Configure CCPA (Do Not Sell is inverse of consent)
				setCCPAStatusMethod.invoke(null, !isEnabled);
				
				Log.d(LCAT, "Vungle GDPR consent configured successfully");
				
			} catch (ClassNotFoundException e) {
				Log.w(LCAT, "Vungle SDK not available, skipping GDPR configuration");
			} catch (Exception e) {
				Log.e(LCAT, "Error configuring Vungle GDPR consent: " + e.getMessage());
			}
		}
	}

	@Kroll.method
	public boolean isAppLovinAvailable()
	{
		try {
			Class.forName("com.applovin.sdk.AppLovinSdk");
			return true;
		} catch (ClassNotFoundException e) {
			return false;
		}
	}

	@Kroll.method
	public boolean isVungleAvailable()
	{
		try {
			Class.forName("com.vungle.warren.Vungle");
			return true;
		} catch (ClassNotFoundException e) {
			return false;
		}
	}

	@Kroll.method
	public boolean isInMobiAvailable()
	{
		try {
			Class.forName("com.inmobi.sdk.InMobiSdk");
			return true;
		} catch (ClassNotFoundException e) {
			return false;
		}
	}

	// NUEVO: Método para añadir adapters problemáticos SOLO cuando se necesiten
	@Kroll.method
	public void enableOptionalMediationNetworks(KrollDict config)
	{
		Log.d(LCAT, "Enabling optional mediation networks...");
		
		if (config != null) {
			boolean enableAppLovin = config.optBoolean("appLovin", false);
			boolean enableVungle = config.optBoolean("vungle", false);
			
			if (enableAppLovin) {
				Log.w(LCAT, "AppLovin adapter not included in build - add 'com.google.ads.mediation:applovin:13.3.1.1' to dependencies");
			}
			
			if (enableVungle) {
				Log.w(LCAT, "Vungle adapter not included in build - add 'com.google.ads.mediation:vungle:7.5.0.1' to dependencies");
			}
		}
	}

	// ===================================================================
	// CONSENT MANAGEMENT METHODS (GDPR/CCPA/UMP)
	// ===================================================================
	@Kroll.method
	public void requestConsent(KrollDict config)
	{
		Log.d(LCAT, "Requesting consent");
		
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			Log.e(LCAT, "Cannot request consent - no current activity");
			return;
		}

		ConsentRequestParameters.Builder paramsBuilder = new ConsentRequestParameters.Builder();
		
		// Handle debug geography and test devices
		if (config != null && config.containsKey("geography")) {
			int geography = config.getInt("geography");
			ConsentDebugSettings.Builder debugBuilder = 
				new ConsentDebugSettings.Builder(activity)
					.setDebugGeography(geography);
			
			// Handle test device IDs for consent testing
			if (config.containsKey("testDeviceIds")) {
				String[] testDeviceIds = config.getStringArray("testDeviceIds");
				if (testDeviceIds != null && testDeviceIds.length > 0) {
					// Add each test device individually using addTestDeviceHashedId()
					for (String deviceId : testDeviceIds) {
						debugBuilder.addTestDeviceHashedId(deviceId);
					}
				}
			}
			
			paramsBuilder.setConsentDebugSettings(debugBuilder.build());
		}
		
		// Tag for under age of consent
		if (config != null && config.containsKey("tagForUnderAgeOfConsent")) {
			boolean underAge = config.getBoolean("tagForUnderAgeOfConsent");
			paramsBuilder.setTagForUnderAgeOfConsent(underAge);
		}
		
		ConsentInformation consentInformation = UserMessagingPlatform.getConsentInformation(activity);
		
		// Request consent info update
		consentInformation.requestConsentInfoUpdate(
			activity,
			paramsBuilder.build(),
			new ConsentInformation.OnConsentInfoUpdateSuccessListener() {
				@Override
				public void onConsentInfoUpdateSuccess() {
					Log.d(LCAT, "Consent info update successful");
					
					// Check if consent form is available
					if (consentInformation.isConsentFormAvailable()) {
						loadConsentForm(activity);
					} else {
						// No consent form needed, fire ready event
						fireConsentReadyEvent();
					}
				}
			},
			new ConsentInformation.OnConsentInfoUpdateFailureListener() {
				@Override
				public void onConsentInfoUpdateFailure(FormError error) {
					Log.e(LCAT, "Consent info update failed: " + error.getMessage());
					
					Map<String, Object> errorEvent = new HashMap<>();
					errorEvent.put("error", error.getMessage());
					errorEvent.put("code", error.getErrorCode());
					fireEvent("consent_error", errorEvent);
				}
			}
		);
	}

	private void loadConsentForm(Activity activity)
	{
		UserMessagingPlatform.loadConsentForm(
			activity,
			new UserMessagingPlatform.OnConsentFormLoadSuccessListener() {
				@Override
				public void onConsentFormLoadSuccess(ConsentForm consentForm) {
					Log.d(LCAT, "Consent form loaded successfully");
					
					// Present consent form
					consentForm.show(activity, new ConsentForm.OnConsentFormDismissedListener() {
						@Override
						public void onConsentFormDismissed(FormError error) {
							if (error != null) {
								Log.e(LCAT, "Consent form error: " + error.getMessage());
								
								Map<String, Object> errorEvent = new HashMap<>();
								errorEvent.put("error", error.getMessage());
								errorEvent.put("code", error.getErrorCode());
								fireEvent("consent_error", errorEvent);
							} else {
								Log.d(LCAT, "Consent form dismissed successfully");
								fireConsentReadyEvent();
							}
						}
					});
				}
			},
			new UserMessagingPlatform.OnConsentFormLoadFailureListener() {
				@Override
				public void onConsentFormLoadFailure(FormError error) {
					Log.e(LCAT, "Consent form load failed: " + error.getMessage());
					
					Map<String, Object> errorEvent = new HashMap<>();
					errorEvent.put("error", error.getMessage());
					errorEvent.put("code", error.getErrorCode());
					fireEvent("consent_error", errorEvent);
				}
			}
		);
	}

	private void fireConsentReadyEvent()
	{
		Map<String, Object> consentEvent = new HashMap<>();
		consentEvent.put("canShowAds", canShowAds());
		consentEvent.put("canShowPersonalizedAds", canShowPersonalizedAds());
		consentEvent.put("isGDPR", isGDPR());
		consentEvent.put("isPrivacyOptionsRequired", isPrivacyOptionsRequired());
		fireEvent("consent_ready", consentEvent);
	}

	// ===================================================================
	// CONSENT STATUS METHODS
	// ===================================================================
	@Kroll.method
	public boolean canShowAds()
	{
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			return false;
		}
		
		ConsentInformation consentInformation = UserMessagingPlatform.getConsentInformation(activity);
		return consentInformation.canRequestAds();
	}

	@Kroll.method
	public boolean canShowPersonalizedAds()
	{
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			return false;
		}
		
		// Check TCF string for personalized ads consent
		SharedPreferences sharedPrefs = activity.getSharedPreferences("IABTCF", 0);
		String tcString = sharedPrefs.getString("IABTCF_TCString", "");
		
		// Simplified check - in real implementation, you'd parse the TC string properly
		return !tcString.isEmpty() && tcString.contains("1");
	}

	@Kroll.method
	public boolean isGDPR()
	{
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			return false;
		}
		
		SharedPreferences sharedPrefs = activity.getSharedPreferences("IABTCF", 0);
		return sharedPrefs.getInt("IABTCF_gdprApplies", 0) == 1;
	}

	@Kroll.method
	public boolean isPrivacyOptionsRequired()
	{
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			return false;
		}
		
		ConsentInformation consentInformation = UserMessagingPlatform.getConsentInformation(activity);
		return consentInformation.getPrivacyOptionsRequirementStatus() == 
			   ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED;
	}

	@Kroll.method
	public void presentPrivacyOptions(KrollDict config)
	{
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			Log.e(LCAT, "Cannot present privacy options - no current activity");
			return;
		}
		
		UserMessagingPlatform.showPrivacyOptionsForm(activity, new ConsentForm.OnConsentFormDismissedListener() {
			@Override
			public void onConsentFormDismissed(FormError error) {
				Map<String, Object> result = new HashMap<>();
				if (error != null) {
					result.put("success", false);
					result.put("error", error.getMessage());
				} else {
					result.put("success", true);
				}
				
				if (config != null && config.containsKey("callback")) {
					// Invoke callback if provided
					fireEvent("privacy_options_dismissed", result);
				}
			}
		});
	}

	@Kroll.method
	public void resetConsent()
	{
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			Log.e(LCAT, "Cannot reset consent - no current activity");
			return;
		}
		
		ConsentInformation consentInformation = UserMessagingPlatform.getConsentInformation(activity);
		consentInformation.reset();
		
		Log.d(LCAT, "Consent information has been reset");
	}

	// ===================================================================
	// AD CREATION METHODS
	// ===================================================================
	@Kroll.method
	public TiAdmobUnifiedRewardedAdProxy createRewarded(KrollDict config)
	{
		Log.d(LCAT, "Creating rewarded ad");
		return new TiAdmobUnifiedRewardedAdProxy(config);
	}

	@Kroll.method
	public TiAdmobUnifiedInterstitialAdProxy createInterstitial(KrollDict config)
	{
		Log.d(LCAT, "Creating interstitial ad");
		return new TiAdmobUnifiedInterstitialAdProxy(config);
	}

	@Kroll.method
	public TiAdmobUnifiedBannerAdProxy createBanner(KrollDict config)
	{
		Log.d(LCAT, "Creating banner ad");
		TiAdmobUnifiedBannerAdProxy proxy = new TiAdmobUnifiedBannerAdProxy();
		if (config != null) {
			proxy.handleCreationDict(config);
		}
		return proxy;
	}

	@Kroll.method
	public TiAdmobUnifiedAdaptiveBannerAdProxy createAdaptiveBanner(KrollDict config)
	{
		Log.d(LCAT, "Creating adaptive banner ad");
		TiAdmobUnifiedAdaptiveBannerAdProxy proxy = new TiAdmobUnifiedAdaptiveBannerAdProxy();
		if (config != null) {
			proxy.handleCreationDict(config);
		}
		return proxy;
	}

	// ===================================================================
	// UTILITY METHODS
	// ===================================================================
	@Kroll.method
	public void setAppVolume(String volume)
	{
		// Convert percentage string to float
		try {
			float volumeValue = Float.parseFloat(volume.replace("%", "")) / 100.0f;
			MobileAds.setAppVolume(volumeValue);
			Log.d(LCAT, "App volume set to: " + volumeValue);
		} catch (NumberFormatException e) {
			Log.e(LCAT, "Invalid volume format: " + volume);
		}
	}

	@Kroll.method
	public void setTestDevice(String deviceId)
	{
		// Set test device through RequestConfiguration
		RequestConfiguration requestConfiguration = new RequestConfiguration.Builder()
			.setTestDeviceIds(Arrays.asList(deviceId))
			.build();
		MobileAds.setRequestConfiguration(requestConfiguration);
		
		Log.d(LCAT, "Test device ID set: " + deviceId);
	}

	@Kroll.method
	public boolean isTestDevice()
	{
		// This would require tracking test device status
		// For now, return false as default implementation
		return false;
	}
}
