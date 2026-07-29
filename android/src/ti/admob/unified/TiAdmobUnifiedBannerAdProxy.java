/**
 * ti.admob.unified - Unified AdMob Banner Proxy for Android
 *
 * Copyright (c) 2025 César Estrada
 * Licensed under the terms of the MIT License
 * Please see the LICENSE included with this distribution for details.
 */

package ti.admob.unified;

import android.app.Activity;
import android.util.Log;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.titanium.TiLifecycle;
import org.appcelerator.titanium.proxy.TiViewProxy;
import org.appcelerator.titanium.util.TiConvert;
import org.appcelerator.titanium.view.TiUIView;

@Kroll.proxy(creatableInModule = TiAdmobUnifiedModule.class)
public class TiAdmobUnifiedBannerAdProxy extends TiViewProxy implements TiLifecycle.OnLifecycleEvent
{
	private static final String LCAT = "TiAdmobUnifiedBannerAdProxy";
	
	private TiAdmobUnifiedBannerAdView bannerView;

	public TiAdmobUnifiedBannerAdProxy()
	{
		super();
		Log.d(LCAT, "Banner proxy created");
	}

	@Override
	public TiUIView createView(Activity activity)
	{
		bannerView = new TiAdmobUnifiedBannerAdView(this);
		return bannerView;
	}
	
	// Handle creation options
	@Override
	public void handleCreationDict(KrollDict options)
	{
		super.handleCreationDict(options);
		Log.d(LCAT, "Handling creation dictionary");
		
		// Process all creation properties
		if (options != null && bannerView != null) {
			bannerView.processProperties(options);
		}
	}
	
	public void processProperties(KrollDict d)
	{
		// Forward properties to the view
		if (bannerView != null) {
			bannerView.processProperties(d);
		}
	}

	@Kroll.method
	public void load()
	{
		Log.d(LCAT, "Loading banner ad");
		if (bannerView == null) {
			getOrCreateView(); // This will create the view and assign to bannerView
		}
		if (bannerView != null) {
			bannerView.loadAd();
		}
	}
	
	// Lifecycle methods
	@Kroll.method
	public void pause()
	{
		Log.d(LCAT, "Pausing banner ad");
		if (bannerView != null) {
			bannerView.pause();
		}
	}
	
	@Kroll.method
	public void resume()
	{
		Log.d(LCAT, "Resuming banner ad");
		if (bannerView != null) {
			bannerView.resume();
		}
	}

	@Kroll.method
	public void destroy()
	{
		Log.d(LCAT, "Destroying banner ad");
		if (bannerView != null) {
			bannerView.destroy();
		}
	}
	
	@Kroll.method
	public void destroyAdViewAndCancelRequest()
	{
		Log.d(LCAT, "destroyAdViewAndCancelRequest() called, delegating to destroy()");
		destroy();
	}

	// Misspelled legacy name kept as deprecated alias for backwards compatibility
	// with consumer JS that may already call destoyAdViewAndCancelRequest().
	@Kroll.method
	public void destoyAdViewAndCancelRequest()
	{
		Log.w(LCAT, "destoyAdViewAndCancelRequest() is misspelled and deprecated; use destroyAdViewAndCancelRequest() or destroy()");
		destroy();
	}

	@Kroll.method
	public boolean isLoaded()
	{
		return bannerView != null && bannerView.isLoaded();
	}

	@Kroll.getProperty
	public String getAdUnitId()
	{
		return TiConvert.toString(getProperty("adUnitId"));
	}

	@Kroll.setProperty
	public void setAdUnitId(String adUnitId)
	{
		Log.d(LCAT, "Setting ad unit ID: " + adUnitId);
		setProperty("adUnitId", adUnitId);
		
		if (bannerView != null) {
			bannerView.setAdUnitId(adUnitId);
		}
	}

	@Kroll.getProperty
	public String getAdSize()
	{
		return TiConvert.toString(getProperty("adSize"));
	}

	@Kroll.setProperty
	public void setAdSize(String adSize)
	{
		Log.d(LCAT, "Setting ad size: " + adSize);
		setProperty("adSize", adSize);
		
		if (bannerView != null) {
			bannerView.setAdSize(adSize);
		}
	}
	
	// Additional properties
	@Kroll.getProperty
	public String[] getKeywords()
	{
		return (String[]) getProperty("keywords");
	}

	@Kroll.setProperty
	public void setKeywords(String[] keywords)
	{
		Log.d(LCAT, "Setting keywords: " + (keywords != null ? java.util.Arrays.toString(keywords) : "null"));
		setProperty("keywords", keywords);
		
		if (bannerView != null) {
			bannerView.setKeywords(keywords);
		}
	}
	
	@Kroll.getProperty
	public String getContentUrl()
	{
		return TiConvert.toString(getProperty("contentUrl"));
	}

	@Kroll.setProperty
	public void setContentUrl(String contentUrl)
	{
		Log.d(LCAT, "Setting content URL: " + contentUrl);
		setProperty("contentUrl", contentUrl);
		
		if (bannerView != null) {
			bannerView.setContentUrl(contentUrl);
		}
	}
	
	@Kroll.getProperty
	public KrollDict getCustomAdSize()
	{
		return (KrollDict) getProperty("customAdSize");
	}

	@Kroll.setProperty
	public void setCustomAdSize(KrollDict customAdSize)
	{
		Log.d(LCAT, "Setting custom ad size");
		setProperty("customAdSize", customAdSize);
		
		if (bannerView != null) {
			bannerView.setCustomAdSize(customAdSize);
		}
	}

	// TiLifecycle.OnLifecycleEvent implementation
	@Override
	public void onDestroy(Activity activity)
	{
		Log.d(LCAT, "Activity destroyed, cleaning up banner ad");
		destroy();
	}
	
	@Override
	public void onPause(Activity activity)
	{
		Log.d(LCAT, "Activity paused, pausing banner ad");
		pause();
	}
	
	@Override
	public void onResume(Activity activity)
	{
		Log.d(LCAT, "Activity resumed, resuming banner ad");
		resume();
	}
	
	@Override
	public void onStart(Activity activity) {
		// No action needed
	}
	
	@Override
	public void onStop(Activity activity) {
		// No action needed
	}

	@Override
	public String getApiName()
	{
		return "ti.admob.unified.BannerAd";
	}
}