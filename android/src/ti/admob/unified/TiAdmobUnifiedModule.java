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
import android.os.Bundle;

import com.google.android.gms.ads.*;
import com.google.android.gms.ads.initialization.InitializationStatus;
import com.google.android.gms.ads.initialization.AdapterStatus;
import java.util.TreeMap;
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
    static int loadErrorCode(com.google.android.gms.ads.LoadAdError error)
    {
        com.google.android.gms.ads.AdError cause = error;
        for (int depth = 0; cause != null && depth < 4; depth++, cause = cause.getCause()) {
            Log.d("TiAdmobUnifiedModule", "Ad load error domain=" + cause.getDomain() + " code=" + cause.getCode());
        }
        return error.getCode();
    }

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
    private Float pendingAppVolume;
	private final Object consentLock = new Object();
	private OperationState consentState = OperationState.NOT_STARTED;
	private Map<String, Object> consentResult;
    private boolean consentResetPending;
    private boolean privacyInFlight;
    private KrollDict queuedConsent;

	@Kroll.method
	public KrollDict getAnchoredAdaptiveBannerSize(double width) {
		if (Double.isNaN(width) || Double.isInfinite(width) || width < 1 || width > Integer.MAX_VALUE) {
			throw new IllegalArgumentException("Banner width must be positive and finite");
		}
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			throw new IllegalStateException("No current activity for adaptive banner sizing");
		}
		AdSize size = AdSize.getLargeAnchoredAdaptiveBannerAdSize(activity, (int) width);
		KrollDict result = new KrollDict();
		result.put("width", size.getWidth());
		result.put("height", size.getHeight());
		result.put("heightUnit", "dp");
		return result;
	}

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
	// There is deliberately no COLLAPSIBLE_TOP / COLLAPSIBLE_BOTTOM constant.
	// Earlier internal builds exported both, carrying the collapsible_top and
	// collapsible_bottom values, which Google's SDK does not accept: the native
	// placement strings are top and bottom, and the view forwards the value
	// verbatim to setCollapsible(), so passing the constants built an invalid
	// request. Pass the native string instead.

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
	@Kroll.method(runOnUiThread = true)
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

		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			failInitialization(new IllegalStateException("No current activity"));
			return;
		}
		final KrollDict snapshot = config == null ? null : new KrollDict();
		if (snapshot != null) snapshot.putAll(config);
		try {
			// Google recommends background initialization even with GMA's default
			// optimization flags. Configuration can also load SDK classes/binders.
			new Thread(() -> initializeSdk(activity, snapshot), "ti-admob-init").start();
		} catch (RuntimeException error) {
			failInitialization(error);
		}
	}

	private void initializeSdk(Activity activity, KrollDict config)
	{
		try {
			// Configure request configuration if provided
			if (config != null) {
				RequestConfiguration.Builder requestConfigBuilder =
					MobileAds.getRequestConfiguration().toBuilder();

				// Test device IDs
				if (config.containsKey("testDeviceIds")) {
					String[] testDeviceIds = config.getStringArray("testDeviceIds");
					if (testDeviceIds != null && testDeviceIds.length > 0) {
						Log.d(LCAT, "Setting test device IDs");
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

			// Skip mediation adapter initialization when the application declares it
			// will not use mediation during this session. Adapters stay bundled; the
			// SDK just does not start them, so a network that never answers cannot
			// hold the first ad request.
			if (config != null && config.optBoolean("disableMediation", false)) {
				Log.d(LCAT, "Disabling mediation adapter initialization for this session");
				MobileAds.disableMediationAdapterInitialization(activity);
			}

			Log.d(LCAT, "Starting AdMob SDK initialization...");

			MobileAds.initialize(activity, new OnInitializationCompleteListener() {
				@Override
				public void onInitializationComplete(InitializationStatus initializationStatus) {
					activity.runOnUiThread(() -> {
						if (pendingAppVolume != null) MobileAds.setAppVolume(pendingAppVolume);
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
					});
				}
			});
		} catch (RuntimeException error) {
			activity.runOnUiThread(() -> failInitialization(error));
		}
	}

	private void failInitialization(RuntimeException error)
	{
		Map<String, Object> event = new HashMap<>();
		event.put("success", false);
		event.put("error", error.getMessage() == null ? error.toString() : error.getMessage());
		event.put("code", -1);
		synchronized (initializationLock) {
			initializationState = OperationState.FAILED;
			initializationResult = event;
		}
		fireEvent("module_initialized", event);
	}

	@Kroll.method(runOnUiThread = true)
	public void openAdInspector()
	{
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			Log.e(LCAT, "Cannot open Ad Inspector - no current activity");
			Map<String, Object> event = new HashMap<>();
			event.put("success", false);
			event.put("error", "No current activity");
			event.put("code", -1);
			fireEvent("ad_inspector_closed", event);
			return;
		}

		activity.runOnUiThread(() -> MobileAds.openAdInspector(activity, new OnAdInspectorClosedListener() {
			@Override
			public void onAdInspectorClosed(AdInspectorError error) {
				Map<String, Object> event = new HashMap<>();
				if (error == null) {
					event.put("success", true);
				} else {
					event.put("success", false);
					event.put("error", error.getMessage());
					event.put("code", error.getCode());
				}
				fireEvent("ad_inspector_closed", event);
			}
		}));
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

	// Converts the `extras` dictionary an application passes from JavaScript into the
	// Bundle AdMob expects. Shared by both banner views so a value keeps the same type
	// no matter which one receives it. Returns null for a null or empty dictionary.
	static Bundle toExtrasBundle(KrollDict extrasDict)
	{
		if (extrasDict == null || extrasDict.isEmpty()) {
			return null;
		}

		Bundle bundle = new Bundle();
		for (String key : extrasDict.keySet()) {
			Object value = extrasDict.get(key);
			if (value instanceof String) {
				bundle.putString(key, (String) value);
			} else if (value instanceof Integer) {
				bundle.putInt(key, (Integer) value);
			} else if (value instanceof Boolean) {
				bundle.putBoolean(key, (Boolean) value);
			} else if (value != null) {
				bundle.putString(key, value.toString());
			}
		}
		return bundle;
	}

	// A read-only snapshot of Google's reported adapter initialization status.
	@Kroll.method
	public KrollDict getMediationStatus()
	{
		OperationState current;
		synchronized (initializationLock) { current = initializationState; }
		String state = "not_started";
		switch (current) {
			case IN_FLIGHT: state = "initializing"; break;
			case COMPLETE: state = "completed"; break;
			case FAILED: state = "failed"; break;
			default: break;
		}
		List<KrollDict> adapters = new ArrayList<>();
		if (current != OperationState.NOT_STARTED) {
			InitializationStatus status = MobileAds.getInitializationStatus();
			if (status != null) {
				for (Map.Entry<String, AdapterStatus> entry : new TreeMap<>(status.getAdapterStatusMap()).entrySet()) {
					AdapterStatus adapter = entry.getValue();
					KrollDict item = new KrollDict();
					item.put("adapterClass", entry.getKey());
					item.put("state", adapter.getInitializationState() == AdapterStatus.State.READY ? "ready" : "not_ready");
					item.put("description", adapter.getDescription());
					item.put("latencyMs", adapter.getLatency());
					adapters.add(item);
				}
			}
		}
		KrollDict result = new KrollDict();
		result.put("initializationState", state);
		result.put("adapters", adapters.toArray());
		return result;
	}

	// ===================================================================
	// CONSENT MANAGEMENT METHODS (GDPR/CCPA/UMP)
	// ===================================================================
	@Kroll.method(runOnUiThread = true)
	public void requestConsent(KrollDict config)
    {
        if (consentResetPending || privacyInFlight) {
            queuedConsent = config == null ? new KrollDict() : config;
            return;
        }
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

        try {
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
                    if (finishPendingConsentReset(activity)) return;
					Log.d(LCAT, "Consent info update successful");

					// The activity captured when requestConsent() was called can already be
					// gone by the time this async callback fires: Titanium's launcher
					// activity hands off to the real TiActivity a moment after launch, and
					// attaching the form to the stale, backgrounded activity lets it build
					// silently without ever becoming visible. Re-resolve the activity here,
					// right before the form actually needs to attach to something.
					Activity showActivity = TiApplication.getInstance().getCurrentActivity();
					if (showActivity == null || showActivity.isFinishing() || showActivity.isDestroyed()) {
						// This is a local timing problem, not a real UMP result: Google
						// already answered whether a form is required. completeConsent()
						// would cache this as terminal and replay it on every later
						// requestConsent() call until resetConsent() wipes real consent
						// state along with it, so fail without caching and let the next
						// requestConsent() call retry from scratch instead.
						Log.e(LCAT, "Cannot present consent form - no valid current activity");
						Map<String, Object> result = new HashMap<>();
						result.put("success", false);
						result.put("canRequestAds", false);
						result.put("privacyOptionsRequired", false);
						// Compatibility payload keys retained for one transition release.
						result.put("canShowAds", false);
						result.put("canShowPersonalizedAds", false);
						result.put("isGDPR", isGDPR());
						result.put("isPrivacyOptionsRequired", false);
						result.put("error", "No current activity when presenting consent form");
						result.put("code", -1);
						synchronized (consentLock) {
							consentState = OperationState.NOT_STARTED;
						}
						fireEvent("consent_error", result);
						fireEvent("consent_complete", result);
						return;
					}
					final Activity finalShowActivity = showActivity;

					UserMessagingPlatform.loadAndShowConsentFormIfRequired(
						finalShowActivity,
						new ConsentForm.OnConsentFormDismissedListener() {
							@Override
							public void onConsentFormDismissed(FormError error) {
								if (error == null) {
									completeConsent(finalShowActivity, null, 0);
								} else {
									completeConsent(finalShowActivity, error.getMessage(), error.getErrorCode());
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
        } catch (RuntimeException error) {
            synchronized (consentLock) { consentState = OperationState.NOT_STARTED; }
            throw error;
        }
	}

	private void completeConsent(Activity activity, String errorMessage, int errorCode)
	{
        if (finishPendingConsentReset(activity)) return;
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
			consentState = errorMessage == null ? OperationState.COMPLETE : OperationState.NOT_STARTED;
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
		
		SharedPreferences sharedPrefs = activity.getSharedPreferences(activity.getPackageName() + "_preferences", 0);
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

	@Kroll.method(runOnUiThread = true)
	public void presentPrivacyOptions(KrollDict config)
	{
		if (privacyInFlight) return;
        if (consentState == OperationState.IN_FLIGHT) {
            Map<String, Object> busy = new HashMap<>();
            busy.put("success", false); busy.put("code", -1);
            busy.put("error", "Consent request is still in progress");
            busy.put("canRequestAds", canRequestAds()); busy.put("privacyOptionsRequired", isPrivacyOptionsRequired());
            fireEvent("privacy_options_dismissed", busy);
            return;
        }
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
		
		privacyInFlight = true;
        UserMessagingPlatform.showPrivacyOptionsForm(activity, new ConsentForm.OnConsentFormDismissedListener() {
			@Override
			public void onConsentFormDismissed(FormError error) {
				privacyInFlight = false;
                if (consentResetPending) {
                    Map<String, Object> cancelled = new HashMap<>();
                    cancelled.put("success", false); cancelled.put("code", -1);
                    cancelled.put("error", "Consent reset during privacy options");
                    cancelled.put("canRequestAds", false); cancelled.put("privacyOptionsRequired", false);
                    fireEvent("privacy_options_dismissed", cancelled);
                    finishPendingConsentReset(activity);
                    return;
                }
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
                synchronized (consentLock) {
                    consentResult = new HashMap<>(result);
                    consentResult.put("canShowAds", result.get("canRequestAds"));
                    consentResult.put("canShowPersonalizedAds", false);
                    consentResult.put("isGDPR", isGDPR());
                    consentResult.put("isPrivacyOptionsRequired", result.get("privacyOptionsRequired"));
                    consentState = error == null ? OperationState.COMPLETE : OperationState.NOT_STARTED;
                }
				fireEvent("privacy_options_dismissed", result);
                KrollDict next = queuedConsent;
                queuedConsent = null;
                if (next != null) requestConsent(next);
			}
		});
	}

    // UMP itself is not cancellable. Wait for its outstanding callback before
    // resetting or starting another update, so it cannot overwrite a newer result.
    private boolean finishPendingConsentReset(Activity activity)
    {
        if (!consentResetPending) return false;
        KrollDict next = queuedConsent;
        queuedConsent = null;
        consentResetPending = false;
        consentState = OperationState.NOT_STARTED;
        resetConsent();
        if (next != null) requestConsent(next);
        else completeConsent(activity, "Consent reset during request", -1);
        return true;
    }

	@Kroll.method(runOnUiThread = true)
	public void resetConsent()
    {
        if (consentState == OperationState.IN_FLIGHT || privacyInFlight) {
            consentResetPending = true;
            queuedConsent = null;
            return;
        }
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
	public KrollDict getTrackingAuthorizationStatus()
	{
		// Portable ATT convention only; this is not a general tracking permission.
		KrollDict result = new KrollDict();
		result.put("status", 3);
		result.put("authorized", true);
		result.put("applicable", false);
		return result;
	}

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
	public TiAdmobUnifiedRewardedInterstitialAdProxy createRewardedInterstitial(KrollDict config)
	{
		Log.d(LCAT, "Creating rewarded interstitial ad");
		return new TiAdmobUnifiedRewardedInterstitialAdProxy(config);
	}

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
	public TiAdmobUnifiedAppOpenAdProxy createAppOpen(KrollDict config)
	{
		Log.d(LCAT, "Creating app open ad");
		return new TiAdmobUnifiedAppOpenAdProxy(config);
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
	@Kroll.method(runOnUiThread = true)
	public void setAppVolume(String volume)
	{
        try {
            String value = volume == null ? "" : volume.trim();
            if (value.endsWith("%")) value = value.substring(0, value.length() - 1).trim();
            double percentage = Double.parseDouble(value);
            if (!Double.isFinite(percentage) || percentage < 0 || percentage > 100) {
                throw new NumberFormatException();
            }
            pendingAppVolume = (float) (percentage / 100.0);
            if (initializationState == OperationState.COMPLETE) MobileAds.setAppVolume(pendingAppVolume);
        } catch (NumberFormatException error) {
            Log.w(LCAT, "App volume requires a finite percentage between 0 and 100");
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
		
		Log.d(LCAT, "Test device ID set");
	}

	@Kroll.method
	public boolean isTestDevice()
	{
		return new AdRequest.Builder()
			.build()
			.isTestDevice(TiApplication.getInstance());
	}
}
