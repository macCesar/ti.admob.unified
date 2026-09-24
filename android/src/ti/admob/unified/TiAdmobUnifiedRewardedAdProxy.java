/**
 * ti.admob.unified - Unified AdMob Rewarded Ad Proxy for Android
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 *
 */
package ti.admob.unified;

import android.app.Activity;
import android.os.Bundle;

import com.google.ads.mediation.admob.AdMobAdapter;
import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.OnUserEarnedRewardListener;
import com.google.android.gms.ads.rewarded.RewardItem;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.KrollProxy;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.kroll.common.Log;
import org.appcelerator.titanium.TiApplication;

import java.util.HashMap;
import java.util.Map;

@Kroll.proxy(creatableInModule = TiAdmobUnifiedModule.class)
public class TiAdmobUnifiedRewardedAdProxy extends KrollProxy
{
	private static final String LCAT = "TiAdmobUnifiedRewardedAdProxy";
	
	// Ad configuration
	private String adUnitId;
    private String requestAdUnitId;
	private boolean autoReload;
	private String[] keywords;
	// Identifies what issued the request. Google reserves it for libraries that
	// wrap the SDK, which is exactly what this module is.
	private String requestAgent;
	private KrollDict extras;
	
	// Ad instance (Android requires fresh ads, so we'll create new instances as needed)
	private RewardedAd rewardedAd;
	private boolean isLoading = false;
	private boolean isShowing = false;
	private boolean isDestroyed = false;
	private boolean destroyedEventFired = false;

	public TiAdmobUnifiedRewardedAdProxy(KrollDict config)
	{
		super();
		
		// Extract configuration
		if (config != null) {
			this.adUnitId = config.optString("adUnitId", "");
			this.autoReload = config.optBoolean("autoReload", false);
			this.requestAgent = config.optString("requestAgent", null);
			
			// Extract keywords
			if (config.containsKey("keywords")) {
				this.keywords = config.getStringArray("keywords");
			}
			
            if (config.containsKey("extras")) this.extras = config.getKrollDict("extras");
		}
		
		Log.d(LCAT, "RewardedAdProxy created with adUnitId: " + this.adUnitId);
	}

    @Kroll.getProperty
    public String getAdUnitId() { return adUnitId; }

    @Kroll.setProperty
    public void setAdUnitId(String value) { adUnitId = value; }

    @Kroll.getProperty
    public boolean getAutoReload() { return autoReload; }

    @Kroll.setProperty
    public void setAutoReload(boolean value) { autoReload = value; }

    @Kroll.getProperty
    public String[] getKeywords() { return keywords; }

    @Kroll.setProperty
    public void setKeywords(String[] value) { keywords = value; }

    @Kroll.getProperty
    public KrollDict getExtras() { return extras; }

    @Kroll.setProperty
    public void setExtras(KrollDict value) { extras = value; }

    @Kroll.getProperty
    public String getRequestAgent() { return requestAgent; }

    @Kroll.setProperty
    public void setRequestAgent(String value) { requestAgent = value; }


	// ===================================================================
	// PUBLIC METHODS
	// ===================================================================
	@Kroll.method(runOnUiThread = true)
	public void load()
	{
		Log.d(LCAT, "Loading rewarded ad");

		if (isDestroyed) {
			Log.w(LCAT, "Ignoring load after rewarded destruction");
			return;
		}
		
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			Log.e(LCAT, "Cannot load ad - no current activity");
			fireErrorEvent("No current activity available", -1);
			return;
		}
		
		if (isLoading || isShowing || rewardedAd != null) {
			Log.w(LCAT, "Ignoring duplicate rewarded load");
			return;
		}
		
		if (adUnitId.isEmpty()) {
			Log.e(LCAT, "Cannot load ad - no ad unit ID provided");
			fireErrorEvent("Ad unit ID is required", TiAdmobUnifiedModule.ERROR_CODE_INVALID_REQUEST);
			return;
		}
		
		requestAdUnitId = adUnitId;
        isLoading = true;
		
		// Build ad request
		AdRequest.Builder adRequestBuilder = new AdRequest.Builder();
		
		// Add keywords if provided
		if (keywords != null && keywords.length > 0) {
			for (String keyword : keywords) {
				adRequestBuilder.addKeyword(keyword);
			}
		}
		
		if (extras != null && !extras.isEmpty()) {
			Bundle extrasBundle = new Bundle();
			for (Map.Entry<String, Object> entry : extras.entrySet()) {
                Object value = entry.getValue();
                if (value instanceof Boolean) extrasBundle.putBoolean(entry.getKey(), (Boolean) value);
                else if (value instanceof Integer) extrasBundle.putInt(entry.getKey(), (Integer) value);
                else if (value instanceof Long) extrasBundle.putLong(entry.getKey(), (Long) value);
                else if (value instanceof Number) extrasBundle.putDouble(entry.getKey(), ((Number) value).doubleValue());
                else if (value instanceof String) extrasBundle.putString(entry.getKey(), (String) value);
            }
			adRequestBuilder.addNetworkExtrasBundle(AdMobAdapter.class, extrasBundle);
		}
		
		if (requestAgent != null && !requestAgent.isEmpty()) {
			adRequestBuilder.setRequestAgent(requestAgent);
		}

		AdRequest adRequest = adRequestBuilder.build();
		
		// Load rewarded ad (Android: create fresh ad instance)
		RewardedAd.load(
			activity,
			adUnitId,
			adRequest,
			new RewardedAdLoadCallback() {
				@Override
				public void onAdLoaded(RewardedAd ad) {
					if (isDestroyed) {
						return;
					}
					Log.d(LCAT, "Rewarded ad loaded successfully");
					
					rewardedAd = ad;
					isLoading = false;
					
					// Set up ad callbacks
					setupAdCallbacks();
					
					// Fire loaded event
					fireEvent(TiAdmobUnifiedModule.AD_LOADED, baseEvent());
				}
				
				@Override
				public void onAdFailedToLoad(LoadAdError error) {
					if (isDestroyed) {
						return;
					}
					Log.e(LCAT, "Rewarded ad failed to load: " + error.getMessage());
					
					isLoading = false;
					
					// Fire failed to load event
					fireErrorEvent(error.getMessage(), TiAdmobUnifiedModule.loadErrorCode(error));
				}
			}
		);
	}

	@Kroll.method(runOnUiThread = true)
	public void show()
	{
		Log.d(LCAT, "Showing rewarded ad");

		if (isDestroyed) {
			fireFailedToShowEvent(
				"Rewarded ad has been destroyed",
				TiAdmobUnifiedModule.ERROR_CODE_INVALID_REQUEST);
			return;
		}
		
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			Log.e(LCAT, "Cannot show ad - no current activity");
			fireFailedToShowEvent("No current activity available", -1);
			return;
		}
		
		if (rewardedAd == null) {
			Log.e(LCAT, "Cannot show ad - ad not loaded");
			fireFailedToShowEvent("Ad not loaded", TiAdmobUnifiedModule.ERROR_CODE_INVALID_REQUEST);
			return;
		}

		if (isShowing) {
			fireFailedToShowEvent(
				"Ad is already showing",
				TiAdmobUnifiedModule.ERROR_CODE_INVALID_REQUEST);
			return;
		}
		
		// Show rewarded ad
		isShowing = true;
		final Map<String, Object> presentedEvent = baseEvent();
        rewardedAd.show(activity, new OnUserEarnedRewardListener() {
            private boolean rewardDelivered;
			@Override
			public void onUserEarnedReward(RewardItem rewardItem) {
				Log.d(LCAT, "User earned reward: " + rewardItem.getType() + " " + rewardItem.getAmount());
				
				// Fire rewarded event with unified format
				if (isDestroyed || rewardDelivered) {
					return;
				}
                rewardDelivered = true;
				Map<String, Object> rewardEvent = new HashMap<>(presentedEvent);
				rewardEvent.put("rewardType", rewardItem.getType());
				rewardEvent.put("rewardAmount", rewardItem.getAmount());
				fireEvent(TiAdmobUnifiedModule.AD_REWARDED, rewardEvent);
			}
		});
	}

	@Kroll.method(runOnUiThread = true)
	public boolean isLoaded()
	{
		return !isDestroyed && rewardedAd != null && !isLoading && !isShowing;
	}

	@Kroll.method(runOnUiThread = true)
	public void destroy()
	{
		if (isDestroyed) {
			return;
		}
		Log.d(LCAT, "Destroying rewarded ad");

		isDestroyed = true;
		if (rewardedAd != null) {
			rewardedAd.setFullScreenContentCallback(null);
		}
		rewardedAd = null;
		isLoading = false;
		isShowing = false;

		if (!destroyedEventFired) {
			destroyedEventFired = true;
			fireEvent(TiAdmobUnifiedModule.AD_DESTROYED, baseEvent());
		}
	}

	@Override
	public void release()
	{
		destroy();
		super.release();
	}

	// ===================================================================
	// PRIVATE HELPER METHODS
	// ===================================================================
	private void setupAdCallbacks()
	{
		if (rewardedAd == null) {
			return;
		}
		
		rewardedAd.setFullScreenContentCallback(new FullScreenContentCallback() {
			@Override
			public void onAdShowedFullScreenContent() {
				if (isDestroyed) {
					return;
				}
				Log.d(LCAT, "Rewarded ad showed full screen content");

				Map<String, Object> event = baseEvent();
				fireEvent(TiAdmobUnifiedModule.AD_OPENED, event);
				fireEvent(TiAdmobUnifiedModule.AD_SHOWED_FULLSCREEN_CONTENT, event);
			}
			
			@Override
			public void onAdDismissedFullScreenContent() {
				if (isDestroyed) {
					return;
				}
				Log.d(LCAT, "Rewarded ad dismissed full screen content");

				rewardedAd = null;
				isShowing = false;
				fireEvent(TiAdmobUnifiedModule.AD_CLOSED, baseEvent());

				if (autoReload) {
					Log.d(LCAT, "Auto-reloading rewarded ad");
					load();
				}
			}
			
			@Override
			public void onAdFailedToShowFullScreenContent(AdError error) {
				if (isDestroyed) {
					return;
				}
				Log.e(LCAT, "Rewarded ad failed to show: " + error.getMessage());

				rewardedAd = null;
				isShowing = false;
				fireFailedToShowEvent(error.getMessage(), error.getCode());
			}
			
			@Override
			public void onAdClicked() {
				if (isDestroyed) {
					return;
				}
				Log.d(LCAT, "Rewarded ad clicked");
				fireEvent(TiAdmobUnifiedModule.AD_CLICKED, baseEvent());
			}
			
			@Override
			public void onAdImpression() {
				if (isDestroyed) {
					return;
				}
				Log.d(LCAT, "Rewarded ad impression recorded");
				fireEvent(TiAdmobUnifiedModule.AD_IMPRESSION, baseEvent());
			}
		});
	}

	private Map<String, Object> baseEvent()
	{
		Map<String, Object> event = new HashMap<>();
		event.put("adUnitId", requestAdUnitId != null ? requestAdUnitId : adUnitId);
		event.put("adType", TiAdmobUnifiedModule.AD_TYPE_REWARDED);
		return event;
	}

	private void fireErrorEvent(String errorMessage, int errorCode)
	{
		Map<String, Object> errorEvent = baseEvent();
		errorEvent.put("error", errorMessage);
		errorEvent.put("message", errorMessage);
		errorEvent.put("code", errorCode);
		fireEvent(TiAdmobUnifiedModule.AD_FAILED_TO_LOAD, errorEvent);
	}

	private void fireFailedToShowEvent(String errorMessage, int errorCode)
	{
		Map<String, Object> errorEvent = baseEvent();
		errorEvent.put("error", errorMessage);
		errorEvent.put("message", errorMessage);
		errorEvent.put("code", errorCode);
		fireEvent(TiAdmobUnifiedModule.AD_FAILED_TO_SHOW, errorEvent);
	}
}
