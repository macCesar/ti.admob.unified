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

	private enum OperationState {
		NOT_STARTED,
		IN_FLIGHT,
		COMPLETE,
		FAILED
	}

	private final Object initializationLock = new Object();
	private OperationState initializationState = OperationState.NOT_STARTED;
	private Map<String, Object> initializationResult;
	private final Object consentLock = new Object();
	private OperationState consentState = OperationState.NOT_STARTED;
	private Map<String, Object> consentResult;

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
	@Kroll.constant public static final String AGE_RESTRICTED_TREATMENT_CHILD = "child";
	@Kroll.constant public static final String AGE_RESTRICTED_TREATMENT_TEEN = "teen";
	@Kroll.constant public static final String AGE_RESTRICTED_TREATMENT_UNSPECIFIED = "unspecified";

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
		Map<String, Object> cachedResult = null;
		synchronized (initializationLock) {
			if (initializationState == OperationState.COMPLETE) {
				cachedResult = initializationResult;
			} else if (initializationState == OperationState.IN_FLIGHT) {
				Log.d(LCAT, "Google Mobile Ads SDK initialization already in flight");
				return;
			} else {
				initializationState = OperationState.IN_FLIGHT;
			}
		}

		if (cachedResult != null) {
			fireEvent("module_initialized", cachedResult);
			return;
		}

		Log.d(LCAT, "Initializing Google Mobile Ads SDK");
		
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			Log.e(LCAT, "Cannot initialize - no current activity");
			Map<String, Object> errorEvent = new HashMap<>();
			errorEvent.put("success", false);
			errorEvent.put("error", "No current activity");
			errorEvent.put("code", -1);
			synchronized (initializationLock) {
				initializationState = OperationState.FAILED;
				initializationResult = errorEvent;
			}
			fireEvent("module_initialized", errorEvent);
			return;
		}

		// Configure request configuration if provided
		if (config != null) {
			RequestConfiguration.Builder requestConfigBuilder =
				MobileAds.getRequestConfiguration().toBuilder();
			
			// Test device IDs
			if (config.containsKey("testDeviceIds")) {
				String[] testDeviceIds = config.getStringArray("testDeviceIds");
				if (testDeviceIds != null && testDeviceIds.length > 0) {
					Log.d(LCAT, "Setting test device IDs: " + Arrays.toString(testDeviceIds));
					requestConfigBuilder.setTestDeviceIds(Arrays.asList(testDeviceIds));
				}
			}
			
			setAgeRestrictedTreatment(requestConfigBuilder, config);
			
			// Max ad content rating
			if (config.containsKey("maxAdContentRating")) {
				String rating = config.getString("maxAdContentRating");
				requestConfigBuilder.setMaxAdContentRating(rating);
			}
			
			MobileAds.setRequestConfiguration(requestConfigBuilder.build());
		}

		Log.d(LCAT, "Starting AdMob SDK initialization...");
		
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
				
				Map<String, Object> event = new HashMap<>();
				event.put("success", true);
				event.put("status", initializationStatus.toString());
				synchronized (initializationLock) {
					initializationState = OperationState.COMPLETE;
					initializationResult = event;
				}
				fireEvent("module_initialized", event);
			}
		});
	}

	private void setAgeRestrictedTreatment(RequestConfiguration.Builder builder, KrollDict config)
	{
		String treatment = null;
		if (config.containsKey("ageRestrictedTreatment")) {
			treatment = config.getString("ageRestrictedTreatment");
		}

		if (treatment == null) {
			boolean legacyChild = config.containsKey("tagForChildDirectedTreatment")
				&& config.getBoolean("tagForChildDirectedTreatment");
			boolean legacyUnderAge = config.containsKey("tagForUnderAgeOfConsent")
				&& config.getBoolean("tagForUnderAgeOfConsent");
			treatment = legacyChild || legacyUnderAge
				? AGE_RESTRICTED_TREATMENT_CHILD
				: AGE_RESTRICTED_TREATMENT_UNSPECIFIED;
		}

		switch (treatment) {
			case AGE_RESTRICTED_TREATMENT_CHILD:
				builder.setAgeRestrictedTreatment(AgeRestrictedTreatment.CHILD);
				break;
			case AGE_RESTRICTED_TREATMENT_TEEN:
				builder.setAgeRestrictedTreatment(AgeRestrictedTreatment.TEEN);
				break;
			default:
				builder.setAgeRestrictedTreatment(AgeRestrictedTreatment.UNSPECIFIED);
				break;
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
				// Only configure Vungle if the SDK is available. Vungle 7.x (Liftoff
				// Monetize) moved the SDK from com.vungle.warren to com.vungle.ads;
				// try the current package first and fall back to the legacy one.
				Class<?> vunglePrivacyClass = findClass(
					"com.vungle.ads.VunglePrivacySettings",
					"com.vungle.warren.VunglePrivacySettings");

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

	// Returns the first of the given class names that is present on the classpath,
	// or throws ClassNotFoundException if none of them are.
	private static Class<?> findClass(String... classNames) throws ClassNotFoundException
	{
		for (String className : classNames) {
			try {
				return Class.forName(className);
			} catch (ClassNotFoundException ignored) {
				// try the next candidate
			}
		}
		throw new ClassNotFoundException(java.util.Arrays.toString(classNames));
	}

	private static boolean isClassAvailable(String... classNames)
	{
		try {
			findClass(classNames);
			return true;
		} catch (ClassNotFoundException e) {
			return false;
		}
	}

	@Kroll.method
	public boolean isAppLovinAvailable()
	{
		return isClassAvailable("com.applovin.sdk.AppLovinSdk");
	}

	@Kroll.method
	public boolean isVungleAvailable()
	{
		// Vungle 7.x (Liftoff Monetize) renamed the package from com.vungle.warren
		// to com.vungle.ads. Probe both so detection works with either adapter.
		return isClassAvailable("com.vungle.ads.VungleAds", "com.vungle.warren.Vungle");
	}

	@Kroll.method
	public boolean isInMobiAvailable()
	{
		return isClassAvailable("com.inmobi.sdk.InMobiSdk");
	}

	// Compatibility method. The core artifact intentionally does not bundle
	// third-party mediation adapters.
	@Kroll.method
	public void enableOptionalMediationNetworks(KrollDict config)
	{
		if (config == null) {
			return;
		}

		if (config.optBoolean("appLovin", false)) {
			Log.d(LCAT, isAppLovinAvailable()
				? "AppLovin adapter is bundled; mediation will use it when AdMob serves it"
				: "AppLovin adapter missing - add 'com.google.ads.mediation:applovin' to android/build.gradle");
		}

		if (config.optBoolean("vungle", false)) {
			Log.d(LCAT, isVungleAvailable()
				? "Vungle adapter is bundled; mediation will use it when AdMob serves it"
				: "Vungle adapter missing - add 'com.google.ads.mediation:vungle' to android/build.gradle");
		}
	}

	// ===================================================================
	// CONSENT MANAGEMENT METHODS (GDPR/CCPA/UMP)
	// ===================================================================
	@Kroll.method
	public void requestConsent(KrollDict config)
	{
		Map<String, Object> cachedResult = null;
		synchronized (consentLock) {
			if (consentState == OperationState.COMPLETE) {
				cachedResult = consentResult;
			} else if (consentState == OperationState.IN_FLIGHT) {
				Log.d(LCAT, "Consent request already in flight");
				return;
			} else {
				consentState = OperationState.IN_FLIGHT;
			}
		}

		if (cachedResult != null) {
			fireEvent("consent_complete", cachedResult);
			return;
		}

		Log.d(LCAT, "Requesting consent");
		
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			Log.e(LCAT, "Cannot request consent - no current activity");
			completeConsent(null, "No current activity", -1);
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

					UserMessagingPlatform.loadAndShowConsentFormIfRequired(
						activity,
						new ConsentForm.OnConsentFormDismissedListener() {
							@Override
							public void onConsentFormDismissed(FormError error) {
								if (error == null) {
									completeConsent(activity, null, 0);
								} else {
									completeConsent(activity, error.getMessage(), error.getErrorCode());
								}
							}
						}
					);
				}
			},
			new ConsentInformation.OnConsentInfoUpdateFailureListener() {
				@Override
				public void onConsentInfoUpdateFailure(FormError error) {
					Log.e(LCAT, "Consent info update failed: " + error.getMessage());
					completeConsent(activity, error.getMessage(), error.getErrorCode());
				}
			}
		);
	}

	private void completeConsent(Activity activity, String errorMessage, int errorCode)
	{
		boolean canRequestAds = false;
		boolean privacyOptionsRequired = false;
		if (activity != null) {
			ConsentInformation information = UserMessagingPlatform.getConsentInformation(activity);
			canRequestAds = information.canRequestAds();
			privacyOptionsRequired = information.getPrivacyOptionsRequirementStatus()
				== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED;
		}

		Map<String, Object> result = new HashMap<>();
		result.put("success", errorMessage == null);
		result.put("canRequestAds", canRequestAds);
		result.put("privacyOptionsRequired", privacyOptionsRequired);
		// Compatibility payload keys retained for one transition release.
		result.put("canShowAds", canRequestAds);
		result.put("canShowPersonalizedAds", false);
		result.put("isGDPR", isGDPR());
		result.put("isPrivacyOptionsRequired", privacyOptionsRequired);
		if (errorMessage != null) {
			result.put("error", errorMessage);
			result.put("code", errorCode);
		}

		synchronized (consentLock) {
			consentState = OperationState.COMPLETE;
			consentResult = result;
		}

		if (errorMessage == null) {
			fireEvent("consent_ready", result);
		} else {
			fireEvent("consent_error", result);
		}
		fireEvent("consent_complete", result);
	}

	// ===================================================================
	// CONSENT STATUS METHODS
	// ===================================================================
	@Kroll.method
	public boolean canShowAds()
	{
		return canRequestAds();
	}

	@Kroll.method
	public boolean canRequestAds()
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
		// Deprecated: UMP deliberately does not expose a publisher-facing
		// "personalized" boolean. GMA applies the collected privacy signals.
		return false;
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
			Map<String, Object> result = new HashMap<>();
			result.put("success", false);
			result.put("error", "No current activity");
			result.put("code", -1);
			result.put("canRequestAds", false);
			result.put("privacyOptionsRequired", false);
			fireEvent("privacy_options_dismissed", result);
			return;
		}
		
		UserMessagingPlatform.showPrivacyOptionsForm(activity, new ConsentForm.OnConsentFormDismissedListener() {
			@Override
			public void onConsentFormDismissed(FormError error) {
				Map<String, Object> result = new HashMap<>();
				if (error != null) {
					result.put("success", false);
					result.put("error", error.getMessage());
					result.put("code", error.getErrorCode());
				} else {
					result.put("success", true);
				}

				ConsentInformation information = UserMessagingPlatform.getConsentInformation(activity);
				result.put("canRequestAds", information.canRequestAds());
				result.put(
					"privacyOptionsRequired",
					information.getPrivacyOptionsRequirementStatus()
						== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED);
				fireEvent("privacy_options_dismissed", result);
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
		synchronized (consentLock) {
			consentState = OperationState.NOT_STARTED;
			consentResult = null;
		}
		
		Log.d(LCAT, "Consent information has been reset");
	}

	// ===================================================================
	// TRACKING AUTHORIZATION
	// ===================================================================
	@Kroll.method
	public void requestTrackingAuthorization()
	{
		// ATT is an Apple platform API. Android completes the same portable
		// contract immediately so consumer code can use one call site.
		Map<String, Object> result = new HashMap<>();
		result.put("status", 3);
		result.put("authorized", true);
		result.put("applicable", false);
		fireEvent("tracking_authorization_completed", result);
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
		RequestConfiguration requestConfiguration = MobileAds
			.getRequestConfiguration()
			.toBuilder()
			.setTestDeviceIds(Arrays.asList(deviceId))
			.build();
		MobileAds.setRequestConfiguration(requestConfiguration);
		
		Log.d(LCAT, "Test device ID set: " + deviceId);
	}

	@Kroll.method
	public boolean isTestDevice()
	{
		return new AdRequest.Builder()
			.build()
			.isTestDevice(TiApplication.getInstance());
	}
}
