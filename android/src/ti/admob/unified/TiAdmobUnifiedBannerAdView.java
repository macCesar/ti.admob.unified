/**
 * ti.admob.unified - Unified AdMob Banner View for Android
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 */

package ti.admob.unified;

import android.app.Activity;
import android.util.Log;

import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.LoadAdError;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.titanium.TiApplication;
import org.appcelerator.titanium.proxy.TiViewProxy;
import org.appcelerator.titanium.view.TiUIView;

import java.util.HashMap;
import java.util.Map;

public class TiAdmobUnifiedBannerAdView extends TiUIView
{
	private static final String LCAT = "TiAdmobUnifiedBannerAdView";
	
	private AdView adView;
	private boolean isAdLoaded = false;
	private String adUnitId;
	private AdSize adSize = AdSize.BANNER;

	public TiAdmobUnifiedBannerAdView(TiViewProxy proxy)
	{
		super(proxy);
		Log.d(LCAT, "Banner view created");
		createAdView();
	}

	private void createAdView()
	{
		Activity activity = TiApplication.getInstance().getCurrentActivity();
		if (activity == null) {
			Log.e(LCAT, "Cannot create banner - no current activity");
			return;
		}

		if (adUnitId == null) {
			Log.d(LCAT, "AdView creation deferred - no ad unit ID yet");
			return;
		}

		adView = new AdView(activity);
		adView.setAdSize(adSize);
		adView.setAdUnitId(adUnitId);
		
		adView.setAdListener(new com.google.android.gms.ads.AdListener() {
			@Override
			public void onAdLoaded() {
				Log.d(LCAT, "Banner ad loaded successfully");
				isAdLoaded = true;
				fireAdEvent(TiAdmobUnifiedModule.AD_LOADED, null);
			}

			@Override
			public void onAdFailedToLoad(LoadAdError loadAdError) {
				Log.e(LCAT, "Banner ad failed to load: " + loadAdError.getMessage());
				isAdLoaded = false;
				
				Map<String, Object> event = new HashMap<>();
				event.put("error", loadAdError.getMessage());
				event.put("code", loadAdError.getCode());
				fireAdEvent(TiAdmobUnifiedModule.AD_FAILED_TO_LOAD, event);
			}

			@Override
			public void onAdClicked() {
				Log.d(LCAT, "Banner ad clicked");
				fireAdEvent(TiAdmobUnifiedModule.AD_CLICKED, null);
			}

			@Override
			public void onAdImpression() {
				Log.d(LCAT, "Banner ad impression recorded");
				fireAdEvent(TiAdmobUnifiedModule.AD_IMPRESSION, null);
			}

			@Override
			public void onAdOpened() {
				Log.d(LCAT, "Banner ad opened");
				fireAdEvent(TiAdmobUnifiedModule.AD_OPENED, null);
			}

			@Override
			public void onAdClosed() {
				Log.d(LCAT, "Banner ad closed");
				fireAdEvent(TiAdmobUnifiedModule.AD_CLOSED, null);
			}
		});

		setNativeView(adView);
		Log.d(LCAT, "AdView created with unit ID: " + adUnitId);
	}

	public void loadAd()
	{
		if (adView == null) {
			Log.e(LCAT, "Cannot load ad - AdView not created");
			return;
		}

		AdRequest adRequest = new AdRequest.Builder().build();
		Log.d(LCAT, "Loading banner ad with unit ID: " + adUnitId);
		adView.loadAd(adRequest);
	}

	public void setAdUnitId(String unitId)
	{
		this.adUnitId = unitId;
		Log.d(LCAT, "Ad unit ID set to: " + unitId);
		
		if (adView == null && unitId != null) {
			createAdView();
		} else if (adView != null) {
			adView.setAdUnitId(unitId);
		}
	}

	public void setAdSize(String sizeString)
	{
		this.adSize = getAdSizeFromString(sizeString);
		Log.d(LCAT, "Ad size set to: " + sizeString);
		
		if (adView != null) {
			adView.setAdSize(this.adSize);
		}
	}

	public boolean isLoaded()
	{
		return isAdLoaded;
	}

	public void destroy()
	{
		if (adView != null) {
			adView.destroy();
			adView = null;
			isAdLoaded = false;
			Log.d(LCAT, "Banner ad destroyed");
			fireAdEvent(TiAdmobUnifiedModule.AD_DESTROYED, null);
		}
	}

	private void fireAdEvent(String eventName, Map<String, Object> data)
	{
		if (data == null) {
			data = new HashMap<>();
		}
		data.put("adUnitId", adUnitId);
		Log.d(LCAT, "Firing event: " + eventName);
		proxy.fireEvent(eventName, data);
	}

	private static AdSize getAdSizeFromString(String sizeString)
	{
		if (sizeString == null) {
			return AdSize.BANNER;
		}

		switch (sizeString.toLowerCase()) {
			case "banner":
				return AdSize.BANNER;
			case "large_banner":
				return AdSize.LARGE_BANNER;
			case "medium_rectangle":
				return AdSize.MEDIUM_RECTANGLE;
			case "full_banner":
				return AdSize.FULL_BANNER;
			case "leaderboard":
				return AdSize.LEADERBOARD;
			case "smart_banner":
				return AdSize.SMART_BANNER;
			default:
				Log.w(LCAT, "Unknown ad size: " + sizeString + ", using BANNER");
				return AdSize.BANNER;
		}
	}
}