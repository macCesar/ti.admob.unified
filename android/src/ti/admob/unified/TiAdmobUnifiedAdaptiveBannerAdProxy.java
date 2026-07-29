/**
 * ti.admob.unified - Unified AdMob Adaptive Banner Proxy for Android
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
public class TiAdmobUnifiedAdaptiveBannerAdProxy extends TiViewProxy implements TiLifecycle.OnLifecycleEvent
{
	private static final String LCAT = "TiAdmobUnifiedAdaptiveBannerAdProxy";
	
	private TiAdmobUnifiedAdaptiveBannerAdView bannerView;

	public TiAdmobUnifiedAdaptiveBannerAdProxy()
	{
		super();
		Log.d(LCAT, "Adaptive banner proxy created");
	}

	@Override
	public TiUIView createView(Activity activity)
	{
		bannerView = new TiAdmobUnifiedAdaptiveBannerAdView(this);
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
		Log.d(LCAT, "Loading adaptive banner ad");
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
		Log.d(LCAT, "Pausing adaptive banner ad");
		if (bannerView != null) {
			bannerView.pause();
		}
	}
	
	@Kroll.method
	public void resume()
	{
		Log.d(LCAT, "Resuming adaptive banner ad");
		if (bannerView != null) {
			bannerView.resume();
		}
	}

	@Kroll.method
	public void destroy()
	{
		Log.d(LCAT, "Destroying adaptive banner ad");
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

	// Misspelled legacy name kept as deprecated alias for backwards compatibility.
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
	public String getAdaptiveType()
	{
		return TiConvert.toString(getProperty("adaptiveType"));
	}

	@Kroll.setProperty
	public void setAdaptiveType(String adaptiveType)
	{
		Log.d(LCAT, "Setting adaptive type: " + adaptiveType);
		setProperty("adaptiveType", adaptiveType);
		
		if (bannerView != null) {
			bannerView.setAdaptiveType(adaptiveType);
		}
	}
	
	@Kroll.getProperty
	public int getMaxHeight()
	{
		return TiConvert.toInt(getProperty("maxHeight"), 50);
	}

	@Kroll.setProperty
	public void setMaxHeight(int maxHeight)
	{
		Log.d(LCAT, "Setting max height: " + maxHeight);
		setProperty("maxHeight", maxHeight);
		
		if (bannerView != null) {
			bannerView.setMaxHeight(maxHeight);
		}
	}
	
	@Kroll.getProperty
	public String getCollapsible()
	{
		return TiConvert.toString(getProperty("collapsible"));
	}

	@Kroll.setProperty
	public void setCollapsible(String collapsible)
	{
		Log.d(LCAT, "Setting collapsible: " + collapsible);
		setProperty("collapsible", collapsible);
		
		if (bannerView != null) {
			bannerView.setCollapsible(collapsible);
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
	
	// TiLifecycle.OnLifecycleEvent implementation
	@Override
	public void onDestroy(Activity activity)
	{
		Log.d(LCAT, "Activity destroyed, cleaning up adaptive banner ad");
		destroy();
	}
	
	@Override
	public void onPause(Activity activity)
	{
		Log.d(LCAT, "Activity paused, pausing adaptive banner ad");
		pause();
	}
	
	@Override
	public void onResume(Activity activity)
	{
		Log.d(LCAT, "Activity resumed, resuming adaptive banner ad");
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
		return "ti.admob.unified.AdaptiveBannerAd";
	}
}