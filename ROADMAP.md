# ti.admob.unified — Roadmap de tipos faltantes

Este documento describe los 4 tipos de ad que la spec `ANALISIS_MODULOS_ADMOB.md`
contempla pero que aún NO están implementados (o están como stubs no funcionales).

Orden recomendado de implementación: del más simple al más complejo. Cada capítulo
describe API a exponer, clases nativas, archivos a crear, estimación, y riesgos
conocidos. Esto es un mapa para decidir sesión por sesión qué vale la pena —
NO es un compromiso a implementar todos.

---

## 1. App Open Ads — `createAppOpen()`

El más simple. API muy parecida a Interstitial. Útil en apps de uso recurrente que
se abren varias veces al día (banking, social, juegos casuales).

**Estado actual:**
- iOS: stub en `TiAdmobUnifiedModule.m` `createAppOpen:` retorna `nil`.
- Android: constante `AD_TYPE_APP_OPEN = "app_open"` declarada en
  `TiAdmobUnifiedModule.java` pero NO existe proxy.

**API JS a exponer (paridad iOS↔Android):**

```js
var appOpenAd = Admob.createAppOpen({
  adUnitId: Admob.TEST_APP_OPEN,
  orientation: 'portrait',  // optional: 'portrait' | 'landscape'
  autoReload: true           // optional
});
appOpenAd.addEventListener(Admob.AD_LOADED, function (e) {});
appOpenAd.addEventListener(Admob.AD_FAILED_TO_LOAD, function (e) {});
appOpenAd.addEventListener(Admob.AD_CLOSED, function (e) {});
appOpenAd.load();
appOpenAd.show();
appOpenAd.isLoaded();   // boolean
appOpenAd.destroy();
```

**Clases nativas:**
- iOS: `GADAppOpenAd` (`GoogleMobileAds.framework/Headers/GADAppOpenAd.h`).
- Android: `com.google.android.gms.ads.appopen.AppOpenAd`.

**Archivos a crear:**

| Archivo | Notas |
|---|---|
| `ios/Classes/TiAdmobUnifiedAppOpenAdProxy.h` | `@interface : TiProxy <GADFullScreenContentDelegate>` |
| `ios/Classes/TiAdmobUnifiedAppOpenAdProxy.m` | Implementación. Patrón copiar de InterstitialAdProxy. |
| `ios/ti.admob.unified.xcodeproj/project.pbxproj` | Agregar las 4 entradas (header/source + Headers/Sources build phase) — usar como referencia los 12 UUIDs `240C0F00...` que ya agregamos para Banner/Interstitial/Rewarded. |
| `android/src/ti/admob/unified/TiAdmobUnifiedAppOpenAdProxy.java` | `@Kroll.proxy(creatableInModule = TiAdmobUnifiedModule.class)` |
| `android/src/ti/admob/unified/TiAdmobUnifiedModule.java` | Agregar `@Kroll.method createAppOpen(KrollDict)` |

**Estimación: 1 sesión (~3-4 horas).**

**Riesgos conocidos:**
- App Open tiene flujo de display único: NO se debe mostrar inmediatamente
  después de cargar — Google recomienda cachear y mostrar al **siguiente**
  foreground. Documentar esto en el JS para el consumer.
- En Android, igual que Interstitial: el objeto se invalida tras mostrar. Hay que
  recargar. El módulo de Android ya tiene patrón de single-use para Interstitial — copiar.
- iOS GMA 13.x usa `GADFullScreenContentDelegate` (unified delegate para
  Interstitial, Rewarded, AppOpen, RewardedInterstitial).

---

## 2. Rewarded Interstitial — `createRewardedInterstitial()`

Híbrido entre Rewarded e Interstitial. El user NO opta in voluntariamente (como
Rewarded) pero igual recibe un reward. Mucho del código se reusa.

**Estado actual:**
- iOS: NO existe proxy.
- Android: constante `AD_TYPE_REWARDED_INTERSTITIAL` y `TEST_REWARDED_INTERSTITIAL`
  declaradas, pero NO existe proxy.

**API JS a exponer:**

```js
var rewardedInterstitialAd = Admob.createRewardedInterstitial({
  adUnitId: Admob.TEST_REWARDED_INTERSTITIAL,
  autoReload: true
});
rewardedInterstitialAd.addEventListener(Admob.AD_LOADED, ...);
rewardedInterstitialAd.addEventListener(Admob.AD_REWARDED, function (e) {
  // e.rewardType, e.rewardAmount
});
rewardedInterstitialAd.addEventListener(Admob.AD_CLOSED, ...);
rewardedInterstitialAd.load();
rewardedInterstitialAd.show();
```

**Clases nativas:**
- iOS: `GADRewardedInterstitialAd` (`GoogleMobileAds.framework/Headers/GADRewardedInterstitialAd.h`).
- Android: `com.google.android.gms.ads.rewardedinterstitial.RewardedInterstitialAd`.

**Archivos a crear:** mismo patrón que App Open arriba.

**Estimación: 1 sesión (~3-4 horas).** Reusa ~80% del código de RewardedAdProxy
con cambios menores en las API calls.

**Riesgos:**
- Mismas reglas single-use Android.
- El reward callback firma puede ser ligeramente distinto entre Rewarded y
  RewardedInterstitial en iOS — verificar al implementar.
- UX: hay regulación más estricta en algunos países sobre rewarded interstitial.
  El consumer debe asegurarse de cumplir.

---

## 3. Adaptive Banner iOS — ✅ COMPLETADO en v1.1.0 (May 28 2026)

Implementado en `ios/Classes/TiAdmobUnifiedAdaptiveBannerAdProxy.h/.m`. Usa
`GADLargeAnchoredAdaptiveBannerAdSizeWithWidth` con sizing dinámico calculado
en `loadAd:` desde el ancho del container. Paridad con Android lograda.

Histórico (cuando estaba pendiente):

**Estado actual:**
- iOS: `createAdaptiveBanner:` en `TiAdmobUnifiedModule.m` retorna `nil` con TODO.
- Android: implementación completa con anchored adaptive banner usando
  `getLargeAnchoredAdaptiveBannerAdSize(activity, adWidth)` (Fase 2 lo dejó al día).

**API JS a exponer (igual que la Android existente):**

```js
var adaptiveBanner = Admob.createAdaptiveBanner({
  adUnitId: Admob.TEST_ADAPTIVE_BANNER,
  // sin adSize fijo - calcula full width automáticamente
});
// Misma surface que createBanner pero con sizing automático.
```

**Clases nativas:**
- iOS: `GADBannerView` + helper `GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)`.
  Para inline adaptive: `GADCurrentOrientationInlineAdaptiveBannerAdSizeWithWidth`.
- Android: `AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize` (ya marcado deprecated
  por Google), reemplazo `getLargeAnchoredAdaptiveBannerAdSize` (lo aplicamos en Fase 2).

**Archivos a crear:**

| Archivo | Notas |
|---|---|
| `ios/Classes/TiAdmobUnifiedAdaptiveBannerAdProxy.h` | `@interface : TiViewProxy` |
| `ios/Classes/TiAdmobUnifiedAdaptiveBannerAdProxy.m` | Patrón muy similar a BannerAdProxy pero con sizing en `loadAd:` |
| Eliminar el stub en `TiAdmobUnifiedModule.m:createAdaptiveBanner:` y devolver el proxy real |
| `ios/ti.admob.unified.xcodeproj/project.pbxproj` | Agregar 4 entradas (mismo patrón que Banner/Interstitial/Rewarded) |

**Estimación: 1-2 sesiones (~5-6 horas).** Es ViewProxy (no TiProxy), tiene más
complejidad de lifecycle. **El bug del Banner runtime actual debe resolverse
primero** — si no, Adaptive iOS heredará el mismo bug.

**Riesgos:**
- Mismas dependencias de lifecycle que Banner (que actualmente tiene issue runtime
  bloqueando — se debe resolver primero).
- El AdSize se debe calcular en cada layout pass (orientación cambia, tamaño
  pantalla cambia). En Banner regular el size es estático.

---

## 4. Native Ads — `createNative()` — el más complejo

Native ads dejan que la app renderee el ad usando assets crudos (image, headline,
body text, CTA button, etc) en lugar de un ad pre-renderizado. Da mucha más
libertad de diseño pero **mucho más** trabajo de implementación.

**Estado actual:**
- iOS: NO existe.
- Android: constante `AD_TYPE_NATIVE` y `TEST_NATIVE` declaradas, pero NO existe proxy.

**Hay 2 enfoques posibles — decidir antes de implementar:**

### Enfoque A — Native "raw" (más flexible, más rápido de portar)

El proxy expone los assets como propiedades, la app los renderea con `Ti.UI.View`s:

```js
var nativeAd = Admob.createNative({
  adUnitId: Admob.TEST_NATIVE
});
nativeAd.addEventListener(Admob.AD_LOADED, function (e) {
  // Acceso a los assets
  myHeadlineLabel.text = nativeAd.headline;
  myBodyLabel.text = nativeAd.body;
  myCTAButton.title = nativeAd.callToAction;
  myIconView.image = nativeAd.iconUrl;  // o blob
  myMediaView.add(nativeAd.mediaView);  // GADMediaView wrapped
});
nativeAd.load();
nativeAd.registerView(containerView, [headlineLabel, bodyLabel, ctaButton, ...]);
nativeAd.destroy();
```

**Pro:** flexibilidad total. El consumer decide layout.
**Contra:** muchos assets para exponer (~10), `mediaView` y `iconView` deben ser
vistas nativas wrapeadas como TiViewProxy. La sesión de tracking de impresión
requiere que el SDK sepa qué views muestran qué assets — eso es lo que hace
`registerView`.

### Enfoque B — Native "templated" (un view predefinido)

El proxy retorna una `Ti.UI.View` ya construida con un layout fijo del módulo:

```js
var nativeView = Admob.createNative({
  adUnitId: Admob.TEST_NATIVE,
  template: 'medium' // 'small' | 'medium'
});
container.add(nativeView);
nativeView.load();
```

**Pro:** mucho más simple de usar.
**Contra:** menos flexibilidad de diseño. El consumer está atado al template.
Google iOS tiene `GADNativeAdView` templates de muestra pero NO los empaqueta
en el SDK — habría que implementarlos a mano.

**Recomendación: enfoque A** — más fiel al SDK nativo, más útil para el
ecosistema. Templates se pueden agregar después como helpers JS.

**Clases nativas:**
- iOS: `GADNativeAd`, `GADNativeAdLoader`, `GADNativeAdView`, `GADMediaView`.
- Android: `com.google.android.gms.ads.nativead.NativeAd`, `NativeAdView`, `MediaView`.

**Archivos a crear (enfoque A):**

| Archivo | Notas |
|---|---|
| `ios/Classes/TiAdmobUnifiedNativeAdProxy.h/m` | El proxy del request + assets |
| `ios/Classes/TiAdmobUnifiedNativeAdView.h/m` | TiViewProxy wrapping GADNativeAdView |
| `ios/Classes/TiAdmobUnifiedMediaView.h/m` | TiViewProxy wrapping GADMediaView |
| `android/src/ti/admob/unified/TiAdmobUnifiedNativeAdProxy.java` | Análogo Android |
| `android/src/ti/admob/unified/TiAdmobUnifiedNativeAdView.java` | TiViewProxy wrapping NativeAdView |

**Estimación: 2-3 sesiones (~8-12 horas).** Es trabajo serio.

**Riesgos:**
- Lifecycle complejo: el SDK requiere que `mediaView`/`iconView` estén en la
  jerarquía VISIBLE y registrados con el ad object ANTES de mostrar.
- Click tracking: el SDK necesita saber qué view es el "CTA" y qué view es el
  background — eso es `registerView` y debe llamarse correctamente.
- Memory: NativeAd debe estar vivo mientras el ad se muestra. Si se destruye
  mientras está visible, leak o crash.
- Paridad iOS↔Android: APIs son SIMILARES pero no idénticas. El TiAdmobUnified
  layer debe normalizar las diferencias.
- Decidir si vale la pena: muchas apps logran su monetization con Banner +
  Interstitial + Rewarded. Native es opcional. Si tu app no necesita layouts
  custom de ads, **puedes saltarte este tipo entero**.

---

## Bloqueador previo: Banner iOS runtime

Antes de cualquier nuevo tipo: el **Banner iOS no se muestra todavía** a pesar
de que el módulo compila/linkea y los proxies se crean. Se aplicaron varios
fixes en la sesión del 28-may-2026:

- `module.xcconfig` con frameworks fantasma (`iAd`, `OpenGLES`, `GLKit`) removidos
- `.xcodeproj` no incluía los proxies en Sources/Headers — agregados
- `TiAdmobUnifiedRewardedAdProxy.m` con `\n` literales (archivo corrupto) — descorruptado
- Banner Proxy `configurationSet` (método inventado) → `_initWithProperties:` patrón estándar
- Banner Proxy isKindOfClass guards en setters + métodos públicos (5)
- Banner View `createBannerView` movido del init al createView del Proxy
- `pendingLoad` flag para diferir `load()` hasta que la view esté lista

Validación pendiente: capturar `--log-level trace` del consumer app al presionar
"Create Banner Ad" + "Show Banner". Sin ese log no se sabe en qué punto del
lifecycle se pierde la view.

**Acción de la siguiente sesión iOS-focused:** lograr Banner runtime + bumpear
los 13 mediation adapters faltantes (AppLovin, FB/Meta, InMobi, IronSource,
Unity, Vungle, etc) que se dejaron en Fase 2.

---

## Trabajo de paridad que SÍ es prioritario (no es tipo nuevo)

Aunque no es uno de los 4 tipos faltantes, hay deficits de paridad iOS↔Android
detectados durante la auditoría que deben tratarse antes de agregar tipos nuevos
o NO romperán el contrato `unified` de manera más profunda:

- Auditoría completa de métodos: confirmar 1:1 entre `TiAdmobUnifiedModule.java`
  `@Kroll.method`s y los métodos declarados en `TiAdmobUnifiedModule.h`.
- Auditoría de eventos: nombres + payload keys deben ser idénticos.
- Auditoría de properties de proxies: mismo conjunto en ambos lados.
- Verificar comportamientos: ¿`autoReload` se comporta igual? ¿`destroy` libera
  el mismo conjunto de recursos?

Estimación: 1 sesión enfocada en el audit + ~1 sesión por hueco descubierto.
