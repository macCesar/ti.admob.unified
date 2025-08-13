/**
 * Titanium SDK
 * Copyright TiDev, Inc. 04/07/2022-Present
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

/** This is generated, do not edit by hand. **/

#include "Proxy.h"

namespace mx {
namespace codigomovil {
namespace tiadmobunified {

class TiAdmobUnifiedModule : public titanium::Proxy
{
public:
	explicit TiAdmobUnifiedModule();

	static void bindProxy(v8::Local<v8::Object>, v8::Local<v8::Context>);
	static v8::Local<v8::FunctionTemplate> getProxyTemplate(v8::Isolate*);
	static v8::Local<v8::FunctionTemplate> getProxyTemplate(v8::Local<v8::Context>);
	static void dispose(v8::Isolate*);

	static jclass javaClass;

private:
	static v8::Persistent<v8::FunctionTemplate> proxyTemplate;
	static v8::Persistent<v8::Object> moduleInstance;

	// Methods -----------------------------------------------------------
	static void resetConsent(const v8::FunctionCallbackInfo<v8::Value>&);
	static void canShowAds(const v8::FunctionCallbackInfo<v8::Value>&);
	static void setAppVolume(const v8::FunctionCallbackInfo<v8::Value>&);
	static void isGDPR(const v8::FunctionCallbackInfo<v8::Value>&);
	static void createInterstitial(const v8::FunctionCallbackInfo<v8::Value>&);
	static void isTestDevice(const v8::FunctionCallbackInfo<v8::Value>&);
	static void presentPrivacyOptions(const v8::FunctionCallbackInfo<v8::Value>&);
	static void canShowPersonalizedAds(const v8::FunctionCallbackInfo<v8::Value>&);
	static void initialize(const v8::FunctionCallbackInfo<v8::Value>&);
	static void setTestDevice(const v8::FunctionCallbackInfo<v8::Value>&);
	static void isPrivacyOptionsRequired(const v8::FunctionCallbackInfo<v8::Value>&);
	static void requestConsent(const v8::FunctionCallbackInfo<v8::Value>&);
	static void createRewarded(const v8::FunctionCallbackInfo<v8::Value>&);

	// Dynamic property accessors ----------------------------------------

};

} // tiadmobunified
} // codigomovil
} // mx
