/**
 * ti.admob.unified - Unified AdMob Interstitial Ad Proxy for Android
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 *
 */
package ti.admob.unified;

import android.app.Activity;

import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.KrollProxy;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.kroll.common.Log;
import org.appcelerator.titanium.TiApplication;

import java.util.HashMap;
import java.util.Map;

@Kroll.proxy(creatableInModule = TiAdmobUnifiedModule.class)
public class TiAdmobUnifiedInterstitialAdProxy extends KrollProxy
{
	private static final String LCAT = "TiAdmobUnifiedInterstitialAdProxy";
	
	// Ad configuration
	private String adUnitId;
	private boolean autoReload;
	private String[] keywords;
	private Map<String, String> extras;
	
	// Ad instance (Android requires fresh ads)
	private InterstitialAd interstitialAd;
	private boolean isLoading = false;

	public TiAdmobUnifiedInterstitialAdProxy(KrollDict config)
	{
		super();
		
		// Extract configuration
		if (config != null) {
			this.adUnitId = config.optString("adUnitId", "");
			this.autoReload = config.optBoolean("autoReload", false);
			
			// Extract keywords
			if (config.containsKey("keywords")) {
				this.keywords = config.getStringArray("keywords");
			}
			
			// Extract extras for mediation networks
			if (config.containsKey("extras")) {
				KrollDict extrasDict = config.getKrollDict("extras");
				if (extrasDict != null) {
					this.extras = new HashMap<>();
					for (String key : extrasDict.keySet()) {
						Object value = extrasDict.get(key);
						if (value != null) {
							this.extras.put(key, value.toString());
						}
					}
				}
			}
		}
		
		Log.d(LCAT, "InterstitialAdProxy created with adUnitId: " + this.adUnitId);
	}

	// ===================================================================
	// PUBLIC METHODS
	// ===================================================================
	@Kroll.method
	public void load()
	{
		Log.d(LCAT, "Loading interstitial ad");
		
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			Log.e(LCAT, "Cannot load ad - no current activity");
			fireErrorEvent("No current activity available", -1);
			return;
		}
		
		if (isLoading) {
			Log.w(LCAT, "Ad is already loading");
			return;
		}
		
		if (adUnitId.isEmpty()) {
			Log.e(LCAT, "Cannot load ad - no ad unit ID provided");
			fireErrorEvent("Ad unit ID is required", TiAdmobUnifiedModule.ERROR_CODE_INVALID_REQUEST);
			return;
		}
		
		isLoading = true;
		
		// Build ad request
		AdRequest.Builder adRequestBuilder = new AdRequest.Builder();
		
		// Add keywords if provided
		if (keywords != null && keywords.length > 0) {
			for (String keyword : keywords) {
				adRequestBuilder.addKeyword(keyword);
			}
		}
		
		AdRequest adRequest = adRequestBuilder.build();
		
		// Load interstitial ad
		InterstitialAd.load(
			activity,
			adUnitId,
			adRequest,
			new InterstitialAdLoadCallback() {
				@Override
				public void onAdLoaded(InterstitialAd ad) {
					Log.d(LCAT, "Interstitial ad loaded successfully");
					
					interstitialAd = ad;
					isLoading = false;
					
					// Set up ad callbacks
					setupAdCallbacks();
					
					// Fire loaded event
					Map<String, Object> event = new HashMap<>();
					event.put("adUnitId", adUnitId);
					fireEvent(TiAdmobUnifiedModule.AD_LOADED, event);
				}
				
				@Override
				public void onAdFailedToLoad(LoadAdError error) {
					Log.e(LCAT, "Interstitial ad failed to load: " + error.getMessage());
					
					isLoading = false;
					
					// Fire failed to load event
					fireErrorEvent(error.getMessage(), error.getCode());
				}
			}
		);
	}

	@Kroll.method
	public void show()
	{
		Log.d(LCAT, "Showing interstitial ad");
		
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			Log.e(LCAT, "Cannot show ad - no current activity");
			fireFailedToShowEvent("No current activity available", -1);
			return;
		}
		
		if (interstitialAd == null) {
			Log.e(LCAT, "Cannot show ad - ad not loaded");
			fireFailedToShowEvent("Ad not loaded", TiAdmobUnifiedModule.ERROR_CODE_INVALID_REQUEST);
			return;
		}
		
		// Show interstitial ad
		interstitialAd.show(activity);
	}

	@Kroll.method
	public boolean isLoaded()
	{
		return interstitialAd != null && !isLoading;
	}

	@Kroll.method
	public void destroy()
	{
		Log.d(LCAT, "Destroying interstitial ad");
		
		if (interstitialAd != null) {
			// Clear ad reference (Android ads are single-use anyway)
			interstitialAd = null;
		}
		
		isLoading = false;
		
		// Fire destroyed event
		Map<String, Object> event = new HashMap<>();
		event.put("adUnitId", adUnitId);
		fireEvent(TiAdmobUnifiedModule.AD_DESTROYED, event);
	}

	// ===================================================================
	// PRIVATE HELPER METHODS
	// ===================================================================
	private void setupAdCallbacks()
	{
		if (interstitialAd == null) {
			return;
		}
		
		interstitialAd.setFullScreenContentCallback(new FullScreenContentCallback() {
			@Override
			public void onAdShowedFullScreenContent() {
				Log.d(LCAT, "Interstitial ad showed full screen content");
				
				// Fire opened event
				Map<String, Object> event = new HashMap<>();
				event.put("adUnitId", adUnitId);
				fireEvent(TiAdmobUnifiedModule.AD_OPENED, event);
				
				// Also fire the fullscreen content event
				fireEvent(TiAdmobUnifiedModule.AD_SHOWED_FULLSCREEN_CONTENT, event);
			}
			
			@Override
			public void onAdDismissedFullScreenContent() {
				Log.d(LCAT, "Interstitial ad dismissed full screen content");
				
				// Fire closed event
				Map<String, Object> event = new HashMap<>();
				event.put("adUnitId", adUnitId);
				fireEvent(TiAdmobUnifiedModule.AD_CLOSED, event);
				
				// Android: Clear the ad since it's single-use
				interstitialAd = null;
				
				// Auto-reload if enabled (create fresh ad for Android)
				if (autoReload) {
					Log.d(LCAT, "Auto-reloading interstitial ad (creating fresh instance for Android)");
					load();
				}
			}
			
			@Override
			public void onAdFailedToShowFullScreenContent(AdError error) {
				Log.e(LCAT, "Interstitial ad failed to show: " + error.getMessage());
				
				// Fire failed to show event
				fireFailedToShowEvent(error.getMessage(), error.getCode());
				
				// Clear the ad since it failed
				interstitialAd = null;
			}
			
			@Override
			public void onAdClicked() {
				Log.d(LCAT, "Interstitial ad clicked");
				
				// Fire clicked event
				Map<String, Object> event = new HashMap<>();
				event.put("adUnitId", adUnitId);
				fireEvent(TiAdmobUnifiedModule.AD_CLICKED, event);
			}
			
			@Override
			public void onAdImpression() {
				Log.d(LCAT, "Interstitial ad impression recorded");
				
				// Fire impression event
				Map<String, Object> event = new HashMap<>();
				event.put("adUnitId", adUnitId);
				fireEvent(TiAdmobUnifiedModule.AD_IMPRESSION, event);
			}
		});
	}

	private void fireErrorEvent(String errorMessage, int errorCode)
	{
		Map<String, Object> errorEvent = new HashMap<>();
		errorEvent.put("adUnitId", adUnitId);
		errorEvent.put("error", errorMessage);
		errorEvent.put("message", errorMessage);
		errorEvent.put("code", errorCode);
		fireEvent(TiAdmobUnifiedModule.AD_FAILED_TO_LOAD, errorEvent);
	}

	private void fireFailedToShowEvent(String errorMessage, int errorCode)
	{
		Map<String, Object> errorEvent = new HashMap<>();
		errorEvent.put("adUnitId", adUnitId);
		errorEvent.put("error", errorMessage);
		errorEvent.put("message", errorMessage);
		errorEvent.put("code", errorCode);
		fireEvent(TiAdmobUnifiedModule.AD_FAILED_TO_SHOW, errorEvent);
	}
}