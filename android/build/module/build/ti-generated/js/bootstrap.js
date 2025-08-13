/**
 * Titanium SDK
 * Copyright TiDev, Inc. 04/07/2022-Present
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 *
 * Warning: This file is GENERATED, and should not be modified
 */
var bootstrap = kroll.NativeModule.require("bootstrap"),
	invoker = kroll.NativeModule.require("invoker"),
	Titanium = kroll.binding("Titanium").Titanium;

function moduleBootstrap(moduleBinding) {
	function lazyGet(object, binding, name, namespace) {
		return bootstrap.lazyGet(object, binding,
			name, namespace, moduleBinding.getBinding);
	}

	var module = moduleBinding.getBinding("mx.codigomovil.tiadmobunified.TiAdmobUnifiedModule")["TiAdmobUnified"];
	var invocationAPIs = module.invocationAPIs = [];
	module.apiName = "TiAdmobUnified";

	function addInvocationAPI(module, moduleNamespace, namespace, api) {
		invocationAPIs.push({ namespace: namespace, api: api });
	}

	addInvocationAPI(module, "TiAdmobUnified", "TiAdmobUnified", "createTiAdmobUnifiedInterstitialAd");addInvocationAPI(module, "TiAdmobUnified", "TiAdmobUnified", "createTiAdmobUnifiedRewardedAd");
		if (!("__propertiesDefined__" in module)) {Object.defineProperties(module, {
"TiAdmobUnifiedInterstitialAd": {
get: function() {
var TiAdmobUnifiedInterstitialAd =  lazyGet(this, "mx.codigomovil.tiadmobunified.TiAdmobUnifiedInterstitialAdProxy", "TiAdmobUnifiedInterstitialAd", "TiAdmobUnifiedInterstitialAd");
return TiAdmobUnifiedInterstitialAd;
},
configurable: true
},
"TiAdmobUnifiedRewardedAd": {
get: function() {
var TiAdmobUnifiedRewardedAd =  lazyGet(this, "mx.codigomovil.tiadmobunified.TiAdmobUnifiedRewardedAdProxy", "TiAdmobUnifiedRewardedAd", "TiAdmobUnifiedRewardedAd");
return TiAdmobUnifiedRewardedAd;
},
configurable: true
},

});
module.constructor.prototype.createTiAdmobUnifiedInterstitialAd = function() {
return new module["TiAdmobUnifiedInterstitialAd"](arguments);
}
module.constructor.prototype.createTiAdmobUnifiedRewardedAd = function() {
return new module["TiAdmobUnifiedRewardedAd"](arguments);
}
}
module.__propertiesDefined__ = true;
return module;

}
exports.bootstrap = moduleBootstrap;
