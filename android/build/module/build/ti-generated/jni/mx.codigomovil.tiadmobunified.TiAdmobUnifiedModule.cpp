/**
 * Titanium SDK
 * Copyright TiDev, Inc. 04/07/2022-Present
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

/** This code is generated, do not edit by hand. **/

#include "mx.codigomovil.tiadmobunified.TiAdmobUnifiedModule.h"

#include "JSException.h"
#include "TypeConverter.h"



#include "mx.codigomovil.tiadmobunified.TiAdmobUnifiedInterstitialAdProxy.h"
#include "mx.codigomovil.tiadmobunified.TiAdmobUnifiedRewardedAdProxy.h"

#include "org.appcelerator.kroll.KrollModule.h"

#define TAG "TiAdmobUnifiedModule"

using namespace v8;

namespace mx {
namespace codigomovil {
namespace tiadmobunified {


Persistent<FunctionTemplate> TiAdmobUnifiedModule::proxyTemplate;
Persistent<Object> TiAdmobUnifiedModule::moduleInstance;
jclass TiAdmobUnifiedModule::javaClass = NULL;

TiAdmobUnifiedModule::TiAdmobUnifiedModule() : titanium::Proxy()
{
}

void TiAdmobUnifiedModule::bindProxy(Local<Object> exports, Local<Context> context)
{
	Isolate* isolate = context->GetIsolate();

	Local<FunctionTemplate> pt = getProxyTemplate(isolate);

	v8::TryCatch tryCatch(isolate);
	Local<Function> constructor;
	MaybeLocal<Function> maybeConstructor = pt->GetFunction(context);
	if (!maybeConstructor.ToLocal(&constructor)) {
		titanium::V8Util::fatalException(isolate, tryCatch);
		return;
	}

	Local<String> nameSymbol = NEW_SYMBOL(isolate, "TiAdmobUnified"); // use symbol over string for efficiency
	MaybeLocal<Object> maybeInstance = constructor->NewInstance(context);
	Local<Object> instance;
	if (!maybeInstance.ToLocal(&instance)) {
		titanium::V8Util::fatalException(isolate, tryCatch);
		return;
	}
	exports->Set(context, nameSymbol, instance);
	moduleInstance.Reset(isolate, instance);
}

void TiAdmobUnifiedModule::dispose(Isolate* isolate)
{
	LOGD(TAG, "dispose()");
	if (!proxyTemplate.IsEmpty()) {
		proxyTemplate.Reset();
	}
	if (!moduleInstance.IsEmpty()) {
	    moduleInstance.Reset();
	}

	titanium::KrollModule::dispose(isolate);
}

Local<FunctionTemplate> TiAdmobUnifiedModule::getProxyTemplate(v8::Isolate* isolate)
{
	Local<Context> context = isolate->GetCurrentContext();
	if (!proxyTemplate.IsEmpty()) {
		return proxyTemplate.Get(isolate);
	}

	LOGD(TAG, "TiAdmobUnifiedModule::getProxyTemplate()");

	javaClass = titanium::JNIUtil::findClass("mx/codigomovil/tiadmobunified/TiAdmobUnifiedModule");
	EscapableHandleScope scope(isolate);

	// use symbol over string for efficiency
	Local<String> nameSymbol = NEW_SYMBOL(isolate, "TiAdmobUnified");

	Local<FunctionTemplate> t = titanium::Proxy::inheritProxyTemplate(
		isolate,
		titanium::KrollModule::getProxyTemplate(isolate),
		javaClass,
		nameSymbol);

	proxyTemplate.Reset(isolate, t);
	t->Set(titanium::Proxy::inheritSymbol.Get(isolate), FunctionTemplate::New(isolate, titanium::Proxy::inherit<TiAdmobUnifiedModule>));

	// Method bindings --------------------------------------------------------
	titanium::SetProtoMethod(isolate, t, "resetConsent", TiAdmobUnifiedModule::resetConsent);
	titanium::SetProtoMethod(isolate, t, "canShowAds", TiAdmobUnifiedModule::canShowAds);
	titanium::SetProtoMethod(isolate, t, "setAppVolume", TiAdmobUnifiedModule::setAppVolume);
	titanium::SetProtoMethod(isolate, t, "isGDPR", TiAdmobUnifiedModule::isGDPR);
	titanium::SetProtoMethod(isolate, t, "createInterstitial", TiAdmobUnifiedModule::createInterstitial);
	titanium::SetProtoMethod(isolate, t, "isTestDevice", TiAdmobUnifiedModule::isTestDevice);
	titanium::SetProtoMethod(isolate, t, "presentPrivacyOptions", TiAdmobUnifiedModule::presentPrivacyOptions);
	titanium::SetProtoMethod(isolate, t, "canShowPersonalizedAds", TiAdmobUnifiedModule::canShowPersonalizedAds);
	titanium::SetProtoMethod(isolate, t, "initialize", TiAdmobUnifiedModule::initialize);
	titanium::SetProtoMethod(isolate, t, "setTestDevice", TiAdmobUnifiedModule::setTestDevice);
	titanium::SetProtoMethod(isolate, t, "isPrivacyOptionsRequired", TiAdmobUnifiedModule::isPrivacyOptionsRequired);
	titanium::SetProtoMethod(isolate, t, "requestConsent", TiAdmobUnifiedModule::requestConsent);
	titanium::SetProtoMethod(isolate, t, "createRewarded", TiAdmobUnifiedModule::createRewarded);

	Local<ObjectTemplate> prototypeTemplate = t->PrototypeTemplate();
	Local<ObjectTemplate> instanceTemplate = t->InstanceTemplate();

	// Delegate indexed property get and set to the Java proxy.
	instanceTemplate->SetIndexedPropertyHandler(titanium::Proxy::getIndexedProperty,
		titanium::Proxy::setIndexedProperty);

	// Constants --------------------------------------------------------------
	JNIEnv *env = titanium::JNIScope::getEnv();
	if (!env) {
		LOGE(TAG, "Failed to get environment in TiAdmobUnifiedModule");
		//return;
	}


			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "ADAPTIVE_INLINE", "adaptive_inline");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "COLLAPSIBLE_TOP", "collapsible_top");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "AD_TYPE_REWARDED_INTERSTITIAL", "rewarded_interstitial");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "AD_CLICKED", "clicked");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "MAX_AD_CONTENT_RATING_GENERAL", "G");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "LARGE_BANNER", "large_banner");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "TEST_REWARDED_INTERSTITIAL", "ca-app-pub-3940256099942544/5354046379");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "AD_TYPE_APP_OPEN", "app_open");

			DEFINE_INT_CONSTANT(isolate, prototypeTemplate, "ERROR_CODE_NETWORK_ERROR", 2);

			DEFINE_INT_CONSTANT(isolate, prototypeTemplate, "ERROR_CODE_INVALID_AD_SIZE", 10);

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "FULLBANNER", "fullbanner");

			DEFINE_INT_CONSTANT(isolate, prototypeTemplate, "ERROR_CODE_SERVER_ERROR", 0);

			DEFINE_INT_CONSTANT(isolate, prototypeTemplate, "DEBUG_GEOGRAPHY_DISABLED", 0);

			DEFINE_INT_CONSTANT(isolate, prototypeTemplate, "DEBUG_GEOGRAPHY_EEA", 1);

			DEFINE_INT_CONSTANT(isolate, prototypeTemplate, "ERROR_CODE_MEDIATION_NO_FILL", 9);

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "AD_TYPE_REWARDED", "rewarded");

			DEFINE_INT_CONSTANT(isolate, prototypeTemplate, "DEBUG_GEOGRAPHY_OTHER", 4);

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "MEDIUM_RECTANGLE", "medium_rectangle");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "COLLAPSIBLE_BOTTOM", "collapsible_bottom");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "AD_CLOSED", "closed");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "AD_FAILED_TO_LOAD", "failed_to_load");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "MAX_AD_CONTENT_RATING_TEEN", "T");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "AD_SHOWED_FULLSCREEN_CONTENT", "showed_fullscreen_content");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "AD_DESTROYED", "destroyed");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "AD_IMPRESSION", "impression");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "TEST_BANNER", "ca-app-pub-3940256099942544/6300978111");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "TEST_NATIVE", "ca-app-pub-3940256099942544/2247696110");

			DEFINE_INT_CONSTANT(isolate, prototypeTemplate, "DEBUG_GEOGRAPHY_REGULATED_US_STATE", 3);

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "AD_TYPE_BANNER", "banner");

			DEFINE_INT_CONSTANT(isolate, prototypeTemplate, "CONSENT_STATUS_NOT_REQUIRED", 1);

			DEFINE_INT_CONSTANT(isolate, prototypeTemplate, "ERROR_CODE_INVALID_REQUEST", 1);

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "AD_FAILED_TO_SHOW", "failed_to_show");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "TEST_APP_OPEN", "ca-app-pub-3940256099942544/9257395921");

			DEFINE_INT_CONSTANT(isolate, prototypeTemplate, "ERROR_CODE_APP_ID_MISSING", 8);

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "AD_TYPE_NATIVE", "native");

			DEFINE_INT_CONSTANT(isolate, prototypeTemplate, "CONSENT_STATUS_UNKNOWN", 0);

			DEFINE_INT_CONSTANT(isolate, prototypeTemplate, "ERROR_CODE_NO_FILL", 3);

			DEFINE_INT_CONSTANT(isolate, prototypeTemplate, "CONSENT_STATUS_REQUIRED", 2);

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "TEST_ADAPTIVE_BANNER", "ca-app-pub-3940256099942544/9214589741");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "AD_TYPE_INTERSTITIAL", "interstitial");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "TEST_INTERSTITIAL_VIDEO", "ca-app-pub-3940256099942544/8691691433");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "AD_LOADED", "loaded");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "ADAPTIVE_ANCHORED", "adaptive_anchored");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "MAX_AD_CONTENT_RATING_PARENTAL_GUIDANCE", "PG");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "AD_OPENED", "opened");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "BANNER", "banner");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "TEST_INTERSTITIAL", "ca-app-pub-3940256099942544/1033173712");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "TEST_REWARDED", "ca-app-pub-3940256099942544/5224354917");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "MAX_AD_CONTENT_RATING_MATURE_AUDIENCE", "MA");

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "AD_REWARDED", "rewarded");

			DEFINE_INT_CONSTANT(isolate, prototypeTemplate, "CONSENT_STATUS_OBTAINED", 3);

			DEFINE_STRING_CONSTANT(isolate, prototypeTemplate, "LEADERBOARD", "leaderboard");


	// Dynamic properties -----------------------------------------------------

	// Accessors --------------------------------------------------------------

	return scope.Escape(t);
}

Local<FunctionTemplate> TiAdmobUnifiedModule::getProxyTemplate(v8::Local<v8::Context> context)
{
	return getProxyTemplate(context->GetIsolate());
}

// Methods --------------------------------------------------------------------
void TiAdmobUnifiedModule::resetConsent(const FunctionCallbackInfo<Value>& args)
{
	LOGD(TAG, "resetConsent()");
	Isolate* isolate = args.GetIsolate();
	Local<Context> context = isolate->GetCurrentContext();
	HandleScope scope(isolate);

	JNIEnv *env = titanium::JNIScope::getEnv();
	if (!env) {
		titanium::JSException::GetJNIEnvironmentError(isolate);
		return;
	}
	static jmethodID methodID = NULL;
	if (!methodID) {
		methodID = env->GetMethodID(TiAdmobUnifiedModule::javaClass, "resetConsent", "()V");
		if (!methodID) {
			const char *error = "Couldn't find proxy method 'resetConsent' with signature '()V'";
			LOGE(TAG, error);
				titanium::JSException::Error(isolate, error);
				return;
		}
	}

	Local<Object> holder = args.Holder();
	if (!JavaObject::isJavaObject(holder)) {
		holder = holder->FindInstanceInPrototypeChain(getProxyTemplate(isolate));
	}
	if (holder.IsEmpty() || holder->IsNull()) {
		if (!moduleInstance.IsEmpty()) {
			holder = moduleInstance.Get(isolate);
			if (holder.IsEmpty() || holder->IsNull()) {
				LOGE(TAG, "Couldn't obtain argument holder");
				args.GetReturnValue().Set(v8::Undefined(isolate));
				return;
			}
		} else {
			LOGE(TAG, "Couldn't obtain argument holder");
			args.GetReturnValue().Set(v8::Undefined(isolate));
			return;
		}
	}
	titanium::Proxy* proxy = NativeObject::Unwrap<titanium::Proxy>(holder);
	if (!proxy) {
		args.GetReturnValue().Set(Undefined(isolate));
		return;
	}

	jvalue* jArguments = 0;


	jobject javaProxy = proxy->getJavaObject();
	if (javaProxy == NULL) {
		args.GetReturnValue().Set(v8::Undefined(isolate));
		return;
	}
	env->CallVoidMethodA(javaProxy, methodID, jArguments);

	proxy->unreferenceJavaObject(javaProxy);



	if (env->ExceptionCheck()) {
		titanium::JSException::fromJavaException(isolate);
		env->ExceptionClear();
	}




	args.GetReturnValue().Set(v8::Undefined(isolate));

}
void TiAdmobUnifiedModule::canShowAds(const FunctionCallbackInfo<Value>& args)
{
	LOGD(TAG, "canShowAds()");
	Isolate* isolate = args.GetIsolate();
	Local<Context> context = isolate->GetCurrentContext();
	HandleScope scope(isolate);

	JNIEnv *env = titanium::JNIScope::getEnv();
	if (!env) {
		titanium::JSException::GetJNIEnvironmentError(isolate);
		return;
	}
	static jmethodID methodID = NULL;
	if (!methodID) {
		methodID = env->GetMethodID(TiAdmobUnifiedModule::javaClass, "canShowAds", "()Z");
		if (!methodID) {
			const char *error = "Couldn't find proxy method 'canShowAds' with signature '()Z'";
			LOGE(TAG, error);
				titanium::JSException::Error(isolate, error);
				return;
		}
	}

	Local<Object> holder = args.Holder();
	if (!JavaObject::isJavaObject(holder)) {
		holder = holder->FindInstanceInPrototypeChain(getProxyTemplate(isolate));
	}
	if (holder.IsEmpty() || holder->IsNull()) {
		if (!moduleInstance.IsEmpty()) {
			holder = moduleInstance.Get(isolate);
			if (holder.IsEmpty() || holder->IsNull()) {
				LOGE(TAG, "Couldn't obtain argument holder");
				args.GetReturnValue().Set(v8::Undefined(isolate));
				return;
			}
		} else {
			LOGE(TAG, "Couldn't obtain argument holder");
			args.GetReturnValue().Set(v8::Undefined(isolate));
			return;
		}
	}
	titanium::Proxy* proxy = NativeObject::Unwrap<titanium::Proxy>(holder);
	if (!proxy) {
		args.GetReturnValue().Set(Undefined(isolate));
		return;
	}

	jvalue* jArguments = 0;


	jobject javaProxy = proxy->getJavaObject();
	if (javaProxy == NULL) {
		args.GetReturnValue().Set(v8::Undefined(isolate));
		return;
	}
	jboolean jResult = (jboolean)env->CallBooleanMethodA(javaProxy, methodID, jArguments);


	proxy->unreferenceJavaObject(javaProxy);



	if (env->ExceptionCheck()) {
		Local<Value> jsException = titanium::JSException::fromJavaException(isolate);
		env->ExceptionClear();
		return;
	}


	Local<Boolean> v8Result = titanium::TypeConverter::javaBooleanToJsBoolean(isolate, env, jResult);



	args.GetReturnValue().Set(v8Result);

}
void TiAdmobUnifiedModule::setAppVolume(const FunctionCallbackInfo<Value>& args)
{
	LOGD(TAG, "setAppVolume()");
	Isolate* isolate = args.GetIsolate();
	Local<Context> context = isolate->GetCurrentContext();
	HandleScope scope(isolate);

	JNIEnv *env = titanium::JNIScope::getEnv();
	if (!env) {
		titanium::JSException::GetJNIEnvironmentError(isolate);
		return;
	}
	static jmethodID methodID = NULL;
	if (!methodID) {
		methodID = env->GetMethodID(TiAdmobUnifiedModule::javaClass, "setAppVolume", "(Ljava/lang/String;)V");
		if (!methodID) {
			const char *error = "Couldn't find proxy method 'setAppVolume' with signature '(Ljava/lang/String;)V'";
			LOGE(TAG, error);
				titanium::JSException::Error(isolate, error);
				return;
		}
	}

	Local<Object> holder = args.Holder();
	if (!JavaObject::isJavaObject(holder)) {
		holder = holder->FindInstanceInPrototypeChain(getProxyTemplate(isolate));
	}
	if (holder.IsEmpty() || holder->IsNull()) {
		if (!moduleInstance.IsEmpty()) {
			holder = moduleInstance.Get(isolate);
			if (holder.IsEmpty() || holder->IsNull()) {
				LOGE(TAG, "Couldn't obtain argument holder");
				args.GetReturnValue().Set(v8::Undefined(isolate));
				return;
			}
		} else {
			LOGE(TAG, "Couldn't obtain argument holder");
			args.GetReturnValue().Set(v8::Undefined(isolate));
			return;
		}
	}
	titanium::Proxy* proxy = NativeObject::Unwrap<titanium::Proxy>(holder);
	if (!proxy) {
		args.GetReturnValue().Set(Undefined(isolate));
		return;
	}

	if (args.Length() < 1) {
		char errorStringBuffer[100];
		sprintf(errorStringBuffer, "setAppVolume: Invalid number of arguments. Expected 1 but got %d", args.Length());
		titanium::JSException::Error(isolate, errorStringBuffer);
		return;
	}

	jvalue jArguments[1];



	
	if (!args[0]->IsNull()) {
		Local<Value> arg_0 = args[0];
		jArguments[0].l =
			titanium::TypeConverter::jsValueToJavaString(
				isolate,
				env, arg_0);
	} else {
		jArguments[0].l = NULL;
	}


	jobject javaProxy = proxy->getJavaObject();
	if (javaProxy == NULL) {
		args.GetReturnValue().Set(v8::Undefined(isolate));
		return;
	}
	env->CallVoidMethodA(javaProxy, methodID, jArguments);

	proxy->unreferenceJavaObject(javaProxy);



				env->DeleteLocalRef(jArguments[0].l);


	if (env->ExceptionCheck()) {
		titanium::JSException::fromJavaException(isolate);
		env->ExceptionClear();
	}




	args.GetReturnValue().Set(v8::Undefined(isolate));

}
void TiAdmobUnifiedModule::isGDPR(const FunctionCallbackInfo<Value>& args)
{
	LOGD(TAG, "isGDPR()");
	Isolate* isolate = args.GetIsolate();
	Local<Context> context = isolate->GetCurrentContext();
	HandleScope scope(isolate);

	JNIEnv *env = titanium::JNIScope::getEnv();
	if (!env) {
		titanium::JSException::GetJNIEnvironmentError(isolate);
		return;
	}
	static jmethodID methodID = NULL;
	if (!methodID) {
		methodID = env->GetMethodID(TiAdmobUnifiedModule::javaClass, "isGDPR", "()Z");
		if (!methodID) {
			const char *error = "Couldn't find proxy method 'isGDPR' with signature '()Z'";
			LOGE(TAG, error);
				titanium::JSException::Error(isolate, error);
				return;
		}
	}

	Local<Object> holder = args.Holder();
	if (!JavaObject::isJavaObject(holder)) {
		holder = holder->FindInstanceInPrototypeChain(getProxyTemplate(isolate));
	}
	if (holder.IsEmpty() || holder->IsNull()) {
		if (!moduleInstance.IsEmpty()) {
			holder = moduleInstance.Get(isolate);
			if (holder.IsEmpty() || holder->IsNull()) {
				LOGE(TAG, "Couldn't obtain argument holder");
				args.GetReturnValue().Set(v8::Undefined(isolate));
				return;
			}
		} else {
			LOGE(TAG, "Couldn't obtain argument holder");
			args.GetReturnValue().Set(v8::Undefined(isolate));
			return;
		}
	}
	titanium::Proxy* proxy = NativeObject::Unwrap<titanium::Proxy>(holder);
	if (!proxy) {
		args.GetReturnValue().Set(Undefined(isolate));
		return;
	}

	jvalue* jArguments = 0;


	jobject javaProxy = proxy->getJavaObject();
	if (javaProxy == NULL) {
		args.GetReturnValue().Set(v8::Undefined(isolate));
		return;
	}
	jboolean jResult = (jboolean)env->CallBooleanMethodA(javaProxy, methodID, jArguments);


	proxy->unreferenceJavaObject(javaProxy);



	if (env->ExceptionCheck()) {
		Local<Value> jsException = titanium::JSException::fromJavaException(isolate);
		env->ExceptionClear();
		return;
	}


	Local<Boolean> v8Result = titanium::TypeConverter::javaBooleanToJsBoolean(isolate, env, jResult);



	args.GetReturnValue().Set(v8Result);

}
void TiAdmobUnifiedModule::createInterstitial(const FunctionCallbackInfo<Value>& args)
{
	LOGD(TAG, "createInterstitial()");
	Isolate* isolate = args.GetIsolate();
	Local<Context> context = isolate->GetCurrentContext();
	HandleScope scope(isolate);

	JNIEnv *env = titanium::JNIScope::getEnv();
	if (!env) {
		titanium::JSException::GetJNIEnvironmentError(isolate);
		return;
	}
	static jmethodID methodID = NULL;
	if (!methodID) {
		methodID = env->GetMethodID(TiAdmobUnifiedModule::javaClass, "createInterstitial", "(Lorg/appcelerator/kroll/KrollDict;)Lmx/codigomovil/tiadmobunified/TiAdmobUnifiedInterstitialAdProxy;");
		if (!methodID) {
			const char *error = "Couldn't find proxy method 'createInterstitial' with signature '(Lorg/appcelerator/kroll/KrollDict;)Lmx/codigomovil/tiadmobunified/TiAdmobUnifiedInterstitialAdProxy;'";
			LOGE(TAG, error);
				titanium::JSException::Error(isolate, error);
				return;
		}
	}

	Local<Object> holder = args.Holder();
	if (!JavaObject::isJavaObject(holder)) {
		holder = holder->FindInstanceInPrototypeChain(getProxyTemplate(isolate));
	}
	if (holder.IsEmpty() || holder->IsNull()) {
		if (!moduleInstance.IsEmpty()) {
			holder = moduleInstance.Get(isolate);
			if (holder.IsEmpty() || holder->IsNull()) {
				LOGE(TAG, "Couldn't obtain argument holder");
				args.GetReturnValue().Set(v8::Undefined(isolate));
				return;
			}
		} else {
			LOGE(TAG, "Couldn't obtain argument holder");
			args.GetReturnValue().Set(v8::Undefined(isolate));
			return;
		}
	}
	titanium::Proxy* proxy = NativeObject::Unwrap<titanium::Proxy>(holder);
	if (!proxy) {
		args.GetReturnValue().Set(Undefined(isolate));
		return;
	}

	if (args.Length() < 1) {
		char errorStringBuffer[100];
		sprintf(errorStringBuffer, "createInterstitial: Invalid number of arguments. Expected 1 but got %d", args.Length());
		titanium::JSException::Error(isolate, errorStringBuffer);
		return;
	}

	jvalue jArguments[1];



	bool isNew_0;
	if (!args[0]->IsNull()) {
		Local<Value> arg_0 = args[0];
		jArguments[0].l =
			titanium::TypeConverter::jsObjectToJavaKrollDict(
				isolate,
				env, arg_0, &isNew_0);
	} else {
		jArguments[0].l = NULL;
	}


	jobject javaProxy = proxy->getJavaObject();
	if (javaProxy == NULL) {
		args.GetReturnValue().Set(v8::Undefined(isolate));
		return;
	}
	jobject jResult = (jobject)env->CallObjectMethodA(javaProxy, methodID, jArguments);


	proxy->unreferenceJavaObject(javaProxy);



			if (isNew_0) {
				env->DeleteLocalRef(jArguments[0].l);
			}


	if (env->ExceptionCheck()) {
		Local<Value> jsException = titanium::JSException::fromJavaException(isolate);
		env->ExceptionClear();
		return;
	}

	if (jResult == NULL) {
		args.GetReturnValue().Set(Null(isolate));
		return;
	}

	Local<Value> v8Result = titanium::TypeConverter::javaObjectToJsValue(isolate, env, jResult);

	env->DeleteLocalRef(jResult);


	args.GetReturnValue().Set(v8Result);

}
void TiAdmobUnifiedModule::isTestDevice(const FunctionCallbackInfo<Value>& args)
{
	LOGD(TAG, "isTestDevice()");
	Isolate* isolate = args.GetIsolate();
	Local<Context> context = isolate->GetCurrentContext();
	HandleScope scope(isolate);

	JNIEnv *env = titanium::JNIScope::getEnv();
	if (!env) {
		titanium::JSException::GetJNIEnvironmentError(isolate);
		return;
	}
	static jmethodID methodID = NULL;
	if (!methodID) {
		methodID = env->GetMethodID(TiAdmobUnifiedModule::javaClass, "isTestDevice", "()Z");
		if (!methodID) {
			const char *error = "Couldn't find proxy method 'isTestDevice' with signature '()Z'";
			LOGE(TAG, error);
				titanium::JSException::Error(isolate, error);
				return;
		}
	}

	Local<Object> holder = args.Holder();
	if (!JavaObject::isJavaObject(holder)) {
		holder = holder->FindInstanceInPrototypeChain(getProxyTemplate(isolate));
	}
	if (holder.IsEmpty() || holder->IsNull()) {
		if (!moduleInstance.IsEmpty()) {
			holder = moduleInstance.Get(isolate);
			if (holder.IsEmpty() || holder->IsNull()) {
				LOGE(TAG, "Couldn't obtain argument holder");
				args.GetReturnValue().Set(v8::Undefined(isolate));
				return;
			}
		} else {
			LOGE(TAG, "Couldn't obtain argument holder");
			args.GetReturnValue().Set(v8::Undefined(isolate));
			return;
		}
	}
	titanium::Proxy* proxy = NativeObject::Unwrap<titanium::Proxy>(holder);
	if (!proxy) {
		args.GetReturnValue().Set(Undefined(isolate));
		return;
	}

	jvalue* jArguments = 0;


	jobject javaProxy = proxy->getJavaObject();
	if (javaProxy == NULL) {
		args.GetReturnValue().Set(v8::Undefined(isolate));
		return;
	}
	jboolean jResult = (jboolean)env->CallBooleanMethodA(javaProxy, methodID, jArguments);


	proxy->unreferenceJavaObject(javaProxy);



	if (env->ExceptionCheck()) {
		Local<Value> jsException = titanium::JSException::fromJavaException(isolate);
		env->ExceptionClear();
		return;
	}


	Local<Boolean> v8Result = titanium::TypeConverter::javaBooleanToJsBoolean(isolate, env, jResult);



	args.GetReturnValue().Set(v8Result);

}
void TiAdmobUnifiedModule::presentPrivacyOptions(const FunctionCallbackInfo<Value>& args)
{
	LOGD(TAG, "presentPrivacyOptions()");
	Isolate* isolate = args.GetIsolate();
	Local<Context> context = isolate->GetCurrentContext();
	HandleScope scope(isolate);

	JNIEnv *env = titanium::JNIScope::getEnv();
	if (!env) {
		titanium::JSException::GetJNIEnvironmentError(isolate);
		return;
	}
	static jmethodID methodID = NULL;
	if (!methodID) {
		methodID = env->GetMethodID(TiAdmobUnifiedModule::javaClass, "presentPrivacyOptions", "(Lorg/appcelerator/kroll/KrollDict;)V");
		if (!methodID) {
			const char *error = "Couldn't find proxy method 'presentPrivacyOptions' with signature '(Lorg/appcelerator/kroll/KrollDict;)V'";
			LOGE(TAG, error);
				titanium::JSException::Error(isolate, error);
				return;
		}
	}

	Local<Object> holder = args.Holder();
	if (!JavaObject::isJavaObject(holder)) {
		holder = holder->FindInstanceInPrototypeChain(getProxyTemplate(isolate));
	}
	if (holder.IsEmpty() || holder->IsNull()) {
		if (!moduleInstance.IsEmpty()) {
			holder = moduleInstance.Get(isolate);
			if (holder.IsEmpty() || holder->IsNull()) {
				LOGE(TAG, "Couldn't obtain argument holder");
				args.GetReturnValue().Set(v8::Undefined(isolate));
				return;
			}
		} else {
			LOGE(TAG, "Couldn't obtain argument holder");
			args.GetReturnValue().Set(v8::Undefined(isolate));
			return;
		}
	}
	titanium::Proxy* proxy = NativeObject::Unwrap<titanium::Proxy>(holder);
	if (!proxy) {
		args.GetReturnValue().Set(Undefined(isolate));
		return;
	}

	if (args.Length() < 1) {
		char errorStringBuffer[100];
		sprintf(errorStringBuffer, "presentPrivacyOptions: Invalid number of arguments. Expected 1 but got %d", args.Length());
		titanium::JSException::Error(isolate, errorStringBuffer);
		return;
	}

	jvalue jArguments[1];



	bool isNew_0;
	if (!args[0]->IsNull()) {
		Local<Value> arg_0 = args[0];
		jArguments[0].l =
			titanium::TypeConverter::jsObjectToJavaKrollDict(
				isolate,
				env, arg_0, &isNew_0);
	} else {
		jArguments[0].l = NULL;
	}


	jobject javaProxy = proxy->getJavaObject();
	if (javaProxy == NULL) {
		args.GetReturnValue().Set(v8::Undefined(isolate));
		return;
	}
	env->CallVoidMethodA(javaProxy, methodID, jArguments);

	proxy->unreferenceJavaObject(javaProxy);



			if (isNew_0) {
				env->DeleteLocalRef(jArguments[0].l);
			}


	if (env->ExceptionCheck()) {
		titanium::JSException::fromJavaException(isolate);
		env->ExceptionClear();
	}




	args.GetReturnValue().Set(v8::Undefined(isolate));

}
void TiAdmobUnifiedModule::canShowPersonalizedAds(const FunctionCallbackInfo<Value>& args)
{
	LOGD(TAG, "canShowPersonalizedAds()");
	Isolate* isolate = args.GetIsolate();
	Local<Context> context = isolate->GetCurrentContext();
	HandleScope scope(isolate);

	JNIEnv *env = titanium::JNIScope::getEnv();
	if (!env) {
		titanium::JSException::GetJNIEnvironmentError(isolate);
		return;
	}
	static jmethodID methodID = NULL;
	if (!methodID) {
		methodID = env->GetMethodID(TiAdmobUnifiedModule::javaClass, "canShowPersonalizedAds", "()Z");
		if (!methodID) {
			const char *error = "Couldn't find proxy method 'canShowPersonalizedAds' with signature '()Z'";
			LOGE(TAG, error);
				titanium::JSException::Error(isolate, error);
				return;
		}
	}

	Local<Object> holder = args.Holder();
	if (!JavaObject::isJavaObject(holder)) {
		holder = holder->FindInstanceInPrototypeChain(getProxyTemplate(isolate));
	}
	if (holder.IsEmpty() || holder->IsNull()) {
		if (!moduleInstance.IsEmpty()) {
			holder = moduleInstance.Get(isolate);
			if (holder.IsEmpty() || holder->IsNull()) {
				LOGE(TAG, "Couldn't obtain argument holder");
				args.GetReturnValue().Set(v8::Undefined(isolate));
				return;
			}
		} else {
			LOGE(TAG, "Couldn't obtain argument holder");
			args.GetReturnValue().Set(v8::Undefined(isolate));
			return;
		}
	}
	titanium::Proxy* proxy = NativeObject::Unwrap<titanium::Proxy>(holder);
	if (!proxy) {
		args.GetReturnValue().Set(Undefined(isolate));
		return;
	}

	jvalue* jArguments = 0;


	jobject javaProxy = proxy->getJavaObject();
	if (javaProxy == NULL) {
		args.GetReturnValue().Set(v8::Undefined(isolate));
		return;
	}
	jboolean jResult = (jboolean)env->CallBooleanMethodA(javaProxy, methodID, jArguments);


	proxy->unreferenceJavaObject(javaProxy);



	if (env->ExceptionCheck()) {
		Local<Value> jsException = titanium::JSException::fromJavaException(isolate);
		env->ExceptionClear();
		return;
	}


	Local<Boolean> v8Result = titanium::TypeConverter::javaBooleanToJsBoolean(isolate, env, jResult);



	args.GetReturnValue().Set(v8Result);

}
void TiAdmobUnifiedModule::initialize(const FunctionCallbackInfo<Value>& args)
{
	LOGD(TAG, "initialize()");
	Isolate* isolate = args.GetIsolate();
	Local<Context> context = isolate->GetCurrentContext();
	HandleScope scope(isolate);

	JNIEnv *env = titanium::JNIScope::getEnv();
	if (!env) {
		titanium::JSException::GetJNIEnvironmentError(isolate);
		return;
	}
	static jmethodID methodID = NULL;
	if (!methodID) {
		methodID = env->GetMethodID(TiAdmobUnifiedModule::javaClass, "initialize", "(Lorg/appcelerator/kroll/KrollDict;)V");
		if (!methodID) {
			const char *error = "Couldn't find proxy method 'initialize' with signature '(Lorg/appcelerator/kroll/KrollDict;)V'";
			LOGE(TAG, error);
				titanium::JSException::Error(isolate, error);
				return;
		}
	}

	Local<Object> holder = args.Holder();
	if (!JavaObject::isJavaObject(holder)) {
		holder = holder->FindInstanceInPrototypeChain(getProxyTemplate(isolate));
	}
	if (holder.IsEmpty() || holder->IsNull()) {
		if (!moduleInstance.IsEmpty()) {
			holder = moduleInstance.Get(isolate);
			if (holder.IsEmpty() || holder->IsNull()) {
				LOGE(TAG, "Couldn't obtain argument holder");
				args.GetReturnValue().Set(v8::Undefined(isolate));
				return;
			}
		} else {
			LOGE(TAG, "Couldn't obtain argument holder");
			args.GetReturnValue().Set(v8::Undefined(isolate));
			return;
		}
	}
	titanium::Proxy* proxy = NativeObject::Unwrap<titanium::Proxy>(holder);
	if (!proxy) {
		args.GetReturnValue().Set(Undefined(isolate));
		return;
	}

	if (args.Length() < 1) {
		char errorStringBuffer[100];
		sprintf(errorStringBuffer, "initialize: Invalid number of arguments. Expected 1 but got %d", args.Length());
		titanium::JSException::Error(isolate, errorStringBuffer);
		return;
	}

	jvalue jArguments[1];



	bool isNew_0;
	if (!args[0]->IsNull()) {
		Local<Value> arg_0 = args[0];
		jArguments[0].l =
			titanium::TypeConverter::jsObjectToJavaKrollDict(
				isolate,
				env, arg_0, &isNew_0);
	} else {
		jArguments[0].l = NULL;
	}


	jobject javaProxy = proxy->getJavaObject();
	if (javaProxy == NULL) {
		args.GetReturnValue().Set(v8::Undefined(isolate));
		return;
	}
	env->CallVoidMethodA(javaProxy, methodID, jArguments);

	proxy->unreferenceJavaObject(javaProxy);



			if (isNew_0) {
				env->DeleteLocalRef(jArguments[0].l);
			}


	if (env->ExceptionCheck()) {
		titanium::JSException::fromJavaException(isolate);
		env->ExceptionClear();
	}




	args.GetReturnValue().Set(v8::Undefined(isolate));

}
void TiAdmobUnifiedModule::setTestDevice(const FunctionCallbackInfo<Value>& args)
{
	LOGD(TAG, "setTestDevice()");
	Isolate* isolate = args.GetIsolate();
	Local<Context> context = isolate->GetCurrentContext();
	HandleScope scope(isolate);

	JNIEnv *env = titanium::JNIScope::getEnv();
	if (!env) {
		titanium::JSException::GetJNIEnvironmentError(isolate);
		return;
	}
	static jmethodID methodID = NULL;
	if (!methodID) {
		methodID = env->GetMethodID(TiAdmobUnifiedModule::javaClass, "setTestDevice", "(Ljava/lang/String;)V");
		if (!methodID) {
			const char *error = "Couldn't find proxy method 'setTestDevice' with signature '(Ljava/lang/String;)V'";
			LOGE(TAG, error);
				titanium::JSException::Error(isolate, error);
				return;
		}
	}

	Local<Object> holder = args.Holder();
	if (!JavaObject::isJavaObject(holder)) {
		holder = holder->FindInstanceInPrototypeChain(getProxyTemplate(isolate));
	}
	if (holder.IsEmpty() || holder->IsNull()) {
		if (!moduleInstance.IsEmpty()) {
			holder = moduleInstance.Get(isolate);
			if (holder.IsEmpty() || holder->IsNull()) {
				LOGE(TAG, "Couldn't obtain argument holder");
				args.GetReturnValue().Set(v8::Undefined(isolate));
				return;
			}
		} else {
			LOGE(TAG, "Couldn't obtain argument holder");
			args.GetReturnValue().Set(v8::Undefined(isolate));
			return;
		}
	}
	titanium::Proxy* proxy = NativeObject::Unwrap<titanium::Proxy>(holder);
	if (!proxy) {
		args.GetReturnValue().Set(Undefined(isolate));
		return;
	}

	if (args.Length() < 1) {
		char errorStringBuffer[100];
		sprintf(errorStringBuffer, "setTestDevice: Invalid number of arguments. Expected 1 but got %d", args.Length());
		titanium::JSException::Error(isolate, errorStringBuffer);
		return;
	}

	jvalue jArguments[1];



	
	if (!args[0]->IsNull()) {
		Local<Value> arg_0 = args[0];
		jArguments[0].l =
			titanium::TypeConverter::jsValueToJavaString(
				isolate,
				env, arg_0);
	} else {
		jArguments[0].l = NULL;
	}


	jobject javaProxy = proxy->getJavaObject();
	if (javaProxy == NULL) {
		args.GetReturnValue().Set(v8::Undefined(isolate));
		return;
	}
	env->CallVoidMethodA(javaProxy, methodID, jArguments);

	proxy->unreferenceJavaObject(javaProxy);



				env->DeleteLocalRef(jArguments[0].l);


	if (env->ExceptionCheck()) {
		titanium::JSException::fromJavaException(isolate);
		env->ExceptionClear();
	}




	args.GetReturnValue().Set(v8::Undefined(isolate));

}
void TiAdmobUnifiedModule::isPrivacyOptionsRequired(const FunctionCallbackInfo<Value>& args)
{
	LOGD(TAG, "isPrivacyOptionsRequired()");
	Isolate* isolate = args.GetIsolate();
	Local<Context> context = isolate->GetCurrentContext();
	HandleScope scope(isolate);

	JNIEnv *env = titanium::JNIScope::getEnv();
	if (!env) {
		titanium::JSException::GetJNIEnvironmentError(isolate);
		return;
	}
	static jmethodID methodID = NULL;
	if (!methodID) {
		methodID = env->GetMethodID(TiAdmobUnifiedModule::javaClass, "isPrivacyOptionsRequired", "()Z");
		if (!methodID) {
			const char *error = "Couldn't find proxy method 'isPrivacyOptionsRequired' with signature '()Z'";
			LOGE(TAG, error);
				titanium::JSException::Error(isolate, error);
				return;
		}
	}

	Local<Object> holder = args.Holder();
	if (!JavaObject::isJavaObject(holder)) {
		holder = holder->FindInstanceInPrototypeChain(getProxyTemplate(isolate));
	}
	if (holder.IsEmpty() || holder->IsNull()) {
		if (!moduleInstance.IsEmpty()) {
			holder = moduleInstance.Get(isolate);
			if (holder.IsEmpty() || holder->IsNull()) {
				LOGE(TAG, "Couldn't obtain argument holder");
				args.GetReturnValue().Set(v8::Undefined(isolate));
				return;
			}
		} else {
			LOGE(TAG, "Couldn't obtain argument holder");
			args.GetReturnValue().Set(v8::Undefined(isolate));
			return;
		}
	}
	titanium::Proxy* proxy = NativeObject::Unwrap<titanium::Proxy>(holder);
	if (!proxy) {
		args.GetReturnValue().Set(Undefined(isolate));
		return;
	}

	jvalue* jArguments = 0;


	jobject javaProxy = proxy->getJavaObject();
	if (javaProxy == NULL) {
		args.GetReturnValue().Set(v8::Undefined(isolate));
		return;
	}
	jboolean jResult = (jboolean)env->CallBooleanMethodA(javaProxy, methodID, jArguments);


	proxy->unreferenceJavaObject(javaProxy);



	if (env->ExceptionCheck()) {
		Local<Value> jsException = titanium::JSException::fromJavaException(isolate);
		env->ExceptionClear();
		return;
	}


	Local<Boolean> v8Result = titanium::TypeConverter::javaBooleanToJsBoolean(isolate, env, jResult);



	args.GetReturnValue().Set(v8Result);

}
void TiAdmobUnifiedModule::requestConsent(const FunctionCallbackInfo<Value>& args)
{
	LOGD(TAG, "requestConsent()");
	Isolate* isolate = args.GetIsolate();
	Local<Context> context = isolate->GetCurrentContext();
	HandleScope scope(isolate);

	JNIEnv *env = titanium::JNIScope::getEnv();
	if (!env) {
		titanium::JSException::GetJNIEnvironmentError(isolate);
		return;
	}
	static jmethodID methodID = NULL;
	if (!methodID) {
		methodID = env->GetMethodID(TiAdmobUnifiedModule::javaClass, "requestConsent", "(Lorg/appcelerator/kroll/KrollDict;)V");
		if (!methodID) {
			const char *error = "Couldn't find proxy method 'requestConsent' with signature '(Lorg/appcelerator/kroll/KrollDict;)V'";
			LOGE(TAG, error);
				titanium::JSException::Error(isolate, error);
				return;
		}
	}

	Local<Object> holder = args.Holder();
	if (!JavaObject::isJavaObject(holder)) {
		holder = holder->FindInstanceInPrototypeChain(getProxyTemplate(isolate));
	}
	if (holder.IsEmpty() || holder->IsNull()) {
		if (!moduleInstance.IsEmpty()) {
			holder = moduleInstance.Get(isolate);
			if (holder.IsEmpty() || holder->IsNull()) {
				LOGE(TAG, "Couldn't obtain argument holder");
				args.GetReturnValue().Set(v8::Undefined(isolate));
				return;
			}
		} else {
			LOGE(TAG, "Couldn't obtain argument holder");
			args.GetReturnValue().Set(v8::Undefined(isolate));
			return;
		}
	}
	titanium::Proxy* proxy = NativeObject::Unwrap<titanium::Proxy>(holder);
	if (!proxy) {
		args.GetReturnValue().Set(Undefined(isolate));
		return;
	}

	if (args.Length() < 1) {
		char errorStringBuffer[100];
		sprintf(errorStringBuffer, "requestConsent: Invalid number of arguments. Expected 1 but got %d", args.Length());
		titanium::JSException::Error(isolate, errorStringBuffer);
		return;
	}

	jvalue jArguments[1];



	bool isNew_0;
	if (!args[0]->IsNull()) {
		Local<Value> arg_0 = args[0];
		jArguments[0].l =
			titanium::TypeConverter::jsObjectToJavaKrollDict(
				isolate,
				env, arg_0, &isNew_0);
	} else {
		jArguments[0].l = NULL;
	}


	jobject javaProxy = proxy->getJavaObject();
	if (javaProxy == NULL) {
		args.GetReturnValue().Set(v8::Undefined(isolate));
		return;
	}
	env->CallVoidMethodA(javaProxy, methodID, jArguments);

	proxy->unreferenceJavaObject(javaProxy);



			if (isNew_0) {
				env->DeleteLocalRef(jArguments[0].l);
			}


	if (env->ExceptionCheck()) {
		titanium::JSException::fromJavaException(isolate);
		env->ExceptionClear();
	}




	args.GetReturnValue().Set(v8::Undefined(isolate));

}
void TiAdmobUnifiedModule::createRewarded(const FunctionCallbackInfo<Value>& args)
{
	LOGD(TAG, "createRewarded()");
	Isolate* isolate = args.GetIsolate();
	Local<Context> context = isolate->GetCurrentContext();
	HandleScope scope(isolate);

	JNIEnv *env = titanium::JNIScope::getEnv();
	if (!env) {
		titanium::JSException::GetJNIEnvironmentError(isolate);
		return;
	}
	static jmethodID methodID = NULL;
	if (!methodID) {
		methodID = env->GetMethodID(TiAdmobUnifiedModule::javaClass, "createRewarded", "(Lorg/appcelerator/kroll/KrollDict;)Lmx/codigomovil/tiadmobunified/TiAdmobUnifiedRewardedAdProxy;");
		if (!methodID) {
			const char *error = "Couldn't find proxy method 'createRewarded' with signature '(Lorg/appcelerator/kroll/KrollDict;)Lmx/codigomovil/tiadmobunified/TiAdmobUnifiedRewardedAdProxy;'";
			LOGE(TAG, error);
				titanium::JSException::Error(isolate, error);
				return;
		}
	}

	Local<Object> holder = args.Holder();
	if (!JavaObject::isJavaObject(holder)) {
		holder = holder->FindInstanceInPrototypeChain(getProxyTemplate(isolate));
	}
	if (holder.IsEmpty() || holder->IsNull()) {
		if (!moduleInstance.IsEmpty()) {
			holder = moduleInstance.Get(isolate);
			if (holder.IsEmpty() || holder->IsNull()) {
				LOGE(TAG, "Couldn't obtain argument holder");
				args.GetReturnValue().Set(v8::Undefined(isolate));
				return;
			}
		} else {
			LOGE(TAG, "Couldn't obtain argument holder");
			args.GetReturnValue().Set(v8::Undefined(isolate));
			return;
		}
	}
	titanium::Proxy* proxy = NativeObject::Unwrap<titanium::Proxy>(holder);
	if (!proxy) {
		args.GetReturnValue().Set(Undefined(isolate));
		return;
	}

	if (args.Length() < 1) {
		char errorStringBuffer[100];
		sprintf(errorStringBuffer, "createRewarded: Invalid number of arguments. Expected 1 but got %d", args.Length());
		titanium::JSException::Error(isolate, errorStringBuffer);
		return;
	}

	jvalue jArguments[1];



	bool isNew_0;
	if (!args[0]->IsNull()) {
		Local<Value> arg_0 = args[0];
		jArguments[0].l =
			titanium::TypeConverter::jsObjectToJavaKrollDict(
				isolate,
				env, arg_0, &isNew_0);
	} else {
		jArguments[0].l = NULL;
	}


	jobject javaProxy = proxy->getJavaObject();
	if (javaProxy == NULL) {
		args.GetReturnValue().Set(v8::Undefined(isolate));
		return;
	}
	jobject jResult = (jobject)env->CallObjectMethodA(javaProxy, methodID, jArguments);


	proxy->unreferenceJavaObject(javaProxy);



			if (isNew_0) {
				env->DeleteLocalRef(jArguments[0].l);
			}


	if (env->ExceptionCheck()) {
		Local<Value> jsException = titanium::JSException::fromJavaException(isolate);
		env->ExceptionClear();
		return;
	}

	if (jResult == NULL) {
		args.GetReturnValue().Set(Null(isolate));
		return;
	}

	Local<Value> v8Result = titanium::TypeConverter::javaObjectToJsValue(isolate, env, jResult);

	env->DeleteLocalRef(jResult);


	args.GetReturnValue().Set(v8Result);

}

// Dynamic property accessors -------------------------------------------------


} // tiadmobunified
} // codigomovil
} // mx
