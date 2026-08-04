# Plan — Paridad de formatos publicitarios

**Nada de lo que sigue está implementado.** Este documento describe trabajo
*propuesto*: qué faltaría escribir, en qué orden, y cómo se comprobaría. Los
datos de la sección «Diagnóstico» sí son medidos, y se indica cómo reproducir
cada medición.

Fecha del diagnóstico: 4 de agosto de 2026
Repositorio: `/Users/cesar/Developer/openSource/TiAdmobUnified/ti.admob.unified`
Versión en curso: `1.2.1`, sin publicar (sin tags de versión ni releases)

## Por qué

`ti.admob.unified` va a reemplazar los dos módulos publicitarios que hoy usa
La Baraja: `ti.android.admob` `11.1.0` en Android y `ti.admob` `8.1.0` en iOS.
Un reemplazo no puede ofrecer menos formatos que lo reemplazado, y hoy ofrece
menos.

**Decisión del 4 de agosto de 2026:** se implementan **App Open** y **Rewarded
Interstitial**. **Native se aplaza**, y su brecha queda aceptada a sabiendas.

El criterio fue el uso, no la dificultad. Un anuncio nativo sólo rinde donde
debe parecer un elemento más de una lista de contenido —un feed, un catálogo,
un listado—. Ninguna de las aplicaciones en curso tiene esa lista: La Baraja es
un juego, y en Cuentas Claras una tarjeta publicitaria entre los movimientos de
dinero de alguien sería impropia. Implementar el formato más caro de los tres
para no usarlo en ninguna parte no se sostiene.

Las condiciones que reabrirían la decisión, y el diseño que habría que resolver
entonces, están en [Native, aplazado](#native-aplazado).

## Diagnóstico

### Formatos, medidos

| Formato | `ti.android.admob` 11.1.0 | `ti.admob` 8.1.0 (iOS) | `ti.admob.unified` 1.2.1 |
|---|---|---|---|
| Banner | Sí | Sí | Sí |
| Banner adaptativo | Sí | No documentado | Sí |
| Interstitial | Sí | Sí | Sí |
| Rewarded | Sí | Sí | Sí |
| App Open | Sí | Sí | **No** |
| Rewarded Interstitial | Sí | No | **No** |
| Native | Sí | No | **No** |

Cómo se midió:

```bash
# Android: clases del .aar del módulo instalado en La Baraja
unzip -p "…/ti.android.admob/11.1.0/m2repository/ti/android/admob/11.1.0/admob-11.1.0.aar" \
  classes.jar > /tmp/c.jar && unzip -l /tmp/c.jar | grep Proxy

# iOS: constantes adType documentadas
sed -e 's/<[^>]*>//g' "…/ti.admob/8.1.0/documentation/index.html" | grep AD_TYPE
```

Android expone `AppOpenAdProxy`, `NativeAdProxy` + `NativeAdView` y
`RewardedInterstitialProxy`. iOS documenta cuatro `adType`, uno de ellos
`AD_TYPE_APP_OPEN`.

### Lo que ya existe aquí

Cuatro proxies por plataforma, ninguno más:

```text
ios/Classes/          TiAdmobUnified{Banner,AdaptiveBanner,Interstitial,Rewarded}AdProxy
android/src/…/        TiAdmobUnified{Banner,AdaptiveBanner,Interstitial,Rewarded}AdProxy
```

Tamaño de los dos que sirven de plantilla:

| Proxy | iOS | Android |
|---|---:|---:|
| Interstitial | 291 líneas | 341 líneas |
| Rewarded | 305 líneas | 357 líneas |

### Deuda existente que este trabajo absorbe

`ios/Classes/TiAdmobUnifiedModule.m:458` declara `createAppOpen:`, que no está
implementado:

```objc
DebugLog(@"[DEBUG] Creating app open ad");
// TODO: Implement app open ad proxy
return nil;
```

Android no exporta ese símbolo, así que las plataformas ya divergen: el mismo
código truena distinto en cada una. La fase 1 lo convierte en una
implementación real, y con eso la asimetría desaparece sin borrar nada.

Las constantes `TEST_APP_OPEN`, `TEST_REWARDED_INTERSTITIAL` y `TEST_NATIVE`
ya existen y apuntan a las unidades demo oficiales de Google. **No se tocan**:
al terminar cada fase dejan de estar reservadas y pasan a tener factory.

## El contrato que hay que replicar

Los proxies nuevos no inventan superficie pública. Copian la que ya cumplen
Interstitial y Rewarded, documentada en
[`documentation/fullscreen.md`](documentation/fullscreen.md) y congelada por
`tests/contract.test.js`.

**Métodos**, idénticos en ambas plataformas:

| Método | Comportamiento exigido |
|---|---|
| `load()` | Una sola petición activa. Llamadas mientras carga, cargado o mostrando se ignoran |
| `show()` | Presenta el anuncio sin usar, o emite `failed_to_show` |
| `isLoaded()` | `true` sólo mientras hay un anuncio sin usar listo |
| `destroy()` | Terminal e idempotente; emite `destroyed` exactamente una vez |

**Eventos**, con `adUnitId` y `adType` en todos los payloads, y `error`,
`message` y `code` añadidos en los fallos:

```text
loaded · failed_to_load · opened · showed_fullscreen_content · closed
clicked · impression · failed_to_show · destroyed
```

Rewarded Interstitial añade `rewarded` con `rewardType` y `rewardAmount`, igual
que Rewarded.

**Propiedades de creación**: `adUnitId`, `autoReload`, `keywords`, `extras`.

**Reglas de ciclo de vida**: los anuncios fullscreen de Google son de un solo
uso; tras presentar o fallar al mostrar, la referencia nativa se limpia *antes*
de emitir el evento terminal; los callbacks nativos tardíos se ignoran después
de `destroy()`.

## Fase 1 — App Open

El formato con mayor prioridad: es el único que está en **los dos** módulos a
reemplazar.

Se escribiría `TiAdmobUnifiedAppOpenAdProxy` en ambas plataformas, tomando el
proxy de Interstitial como plantilla y sustituyendo la clase de Google
(`GADAppOpenAd` en iOS, `AppOpenAd` en Android). En iOS reemplaza el stub de
`TiAdmobUnifiedModule.m:458`; en Android hay que exportar `createAppOpen` por
primera vez.

Puntos que exigen decisión o verificación antes de escribir:

- **Firma vigente de carga.** Versiones anteriores de GMA pedían orientación al
  cargar un App Open. Verificar contra los SDK que este módulo empaqueta —
  iOS `13.7.0`, Android `25.4.0` — y no contra tutoriales viejos.
- **Caducidad.** Google documenta que un App Open expira a las cuatro horas de
  solicitado. Hay que decidir si el proxy vigila esa ventana y emite algo, o si
  se limita a `isLoaded()` y deja la política al consumidor. Recomendación:
  lo segundo, coherente con que el módulo no impone políticas.
- **Quién decide cuándo se muestra.** El módulo no debe engancharse solo al
  regreso a primer plano: eso es política de la app, y mostrarlo encima de otra
  pantalla completa es justo lo que Google prohíbe. El proxy expone `show()` y
  el consumidor elige.

## Fase 2 — Rewarded Interstitial

El más barato de los dos: `GADRewardedInterstitialAd` / `RewardedInterstitialAd`
tienen la misma forma que el Rewarded que ya existe, incluida la recompensa.

Se escribiría `TiAdmobUnifiedRewardedInterstitialAdProxy` partiendo del Rewarded
actual, conservando el evento `rewarded` con `rewardType` y `rewardAmount`, y la
regla de que cerrar el anuncio no prueba que la recompensa se ganó.

Punto a verificar antes de escribir: Google exige un **aviso previo** al usuario
para este formato, distinto del rewarded normal. Confirmar el requisito vigente
en la guía oficial y decidir si es responsabilidad documentada del consumidor
(recomendado) o algo que el módulo intente imponer (no recomendado).

## Native, aplazado

**No es una fase.** Está fuera del trabajo en curso por la decisión del 4 de
agosto de 2026. Lo que sigue queda escrito para quien lo reabra, no para quien
lo ejecute ahora.

### Qué reabriría la decisión

Una sola condición, y es de producto, no técnica: **que alguna aplicación tenga
una lista de contenido donde un anuncio deba parecer un elemento más.** Un feed,
un catálogo, un listado de artículos. Mientras no exista esa lista, el formato
no tiene dónde ir.

Dos señales que *no* bastan para reabrirla: que el módulo a reemplazar lo tenga,
y que sea técnicamente posible. Ambas son ciertas hoy y ninguna produce un
anuncio que alguien quiera mostrar.

### Por qué es el más caro de los tres

Un anuncio nativo no es una vista que se coloca y ya. Google exige un
`GADNativeAdView` / `NativeAdView` como contenedor, y que **cada pieza** —
titular, icono, cuerpo, botón, media, calificación, anunciante — se registre
contra una subvista concreta. De esos registros salen la medición de
impresiones y el manejo de clics; sin ellos no hay formato válido. Se suman el
distintivo AdChoices y la atribución obligatoria.

### Opción A — El layout lo trae el módulo

Es lo que hace `ti.android.admob`, y está medido: el `.aar` empaqueta
`res/layout/ad_app_install.xml` (6 899 bytes) y `res/layout/ad_content.xml`
(6 969 bytes), y expone propiedades de color (`convertColorProp`) para
personalizarlo.

- A favor: el registro de assets queda resuelto dentro del módulo, es la vía
  probada, y la API pública es mínima.
- En contra: el anuncio no se parece a la app; la personalización se limita a
  lo que el módulo decida exponer; y en iOS habría que escribir el layout
  equivalente desde cero, porque ahí no hay nada que copiar.

### Opción B — Las vistas las aporta el consumidor

El proxy recibiría vistas Alloy y las registraría como slots de assets.

- A favor: el anuncio se integra con el diseño de la app, que es el motivo por
  el que existe el formato nativo.
- En contra: hay que diseñar la API desde cero; hay que alcanzar la vista
  nativa por debajo de cada proxy de Titanium; y hay que sobrevivir a que
  Titanium recree o reutilice vistas bajo los pies del registro. En Android se
  suma que `NativeAdView` debe ser el padre de todos los assets, así que el
  proxy tendría que poseer el contenedor y las vistas de la app vivir dentro.

### Por dónde empezar el día que se reabra

1. Contestar primero la pregunta de producto: ¿esa lista quiere un anuncio
   *integrado a su diseño*, o le basta un bloque presentable y aparte? Si es lo
   segundo, la opción A cierra el tema con bastante menos riesgo y no hay nada
   que diseñar.
2. Localizar el repositorio público de `ti.android.admob` como referencia de la
   opción A. El `.aar` está compilado y su documentación es la plantilla vacía
   de Titanium (851 bytes, sin una sola mención de «native»), así que del
   binario no se aprende el diseño.
3. Elegir la opción **antes** de escribir código. Las dos son incompatibles: la
   A entrega un layout cerrado, la B una API de registro de vistas. Migrar de
   una a la otra después sería romper la superficie pública.

## Invariantes

Se conservan durante todo el trabajo:

- **Una sola API pública para ambas plataformas.** Ningún formato nuevo puede
  obligar al consumidor a ramificar por plataforma.
- **Nada de IDs reales.** Sólo las constantes `TEST_*` oficiales de Google en
  código, pruebas, ejemplos y documentación.
- **No se borran constantes ni métodos existentes.**
- **La documentación se actualiza en el mismo commit que el código**, con
  entrada en `CHANGELOG.md`, tal como se hizo con los formatos actuales.
- **Los seis adaptadores de mediación no se tocan**, y `disableMediation` sigue
  funcionando igual para los formatos nuevos.

## Fuera de alcance

- **Native.** Aplazado por decisión del 4 de agosto de 2026, no por bloqueo
  técnico. La brecha contra `ti.android.admob` se acepta a sabiendas mientras
  ninguna aplicación tenga dónde poner el formato.
- Cambiar el contrato de banners, privacidad o mediación.
- Publicar el módulo: tag, release y repositorio público siguen siendo una
  decisión aparte.
- Re-vendorizar en Cuentas Claras antes de que las fases estén validadas en
  hardware. Cuentas Claras sólo usa banners y no gana nada con estos formatos.

## Cómo se comprobaría cada fase

Ninguna fase se daría por terminada sin las cuatro cosas, en orden:

1. **Compilación de ambas plataformas** desde el commit de la fase:
   ```bash
   ti build -p ios --build-only --project-dir ios --no-prompt
   ti build -p android --build-only --project-dir android --no-prompt
   ./scripts/verify-artifacts.sh
   ```
2. **Pruebas de contrato** en `tests/contract.test.js` para el proxy nuevo:
   mismos métodos, mismos eventos, mismos payloads, `destroy()` terminal e
   idempotente. Cada aserción nueva se valida con un **control positivo** —
   mutar la fuente y confirmar que la prueba falla cuando debe — antes de darla
   por buena. Una prueba que nunca se ha visto fallar no es una prueba.
3. **Documentación y ejemplo**: página o sección propia, `example/app.js` con
   los botones que ejerciten carga y presentación por separado, y la constante
   `TEST_*` correspondiente dejando de figurar como reservada en
   `documentation/api-reference.md` y `documentation/getting-started.md`.
4. **Validación en hardware**, que es la única que cierra de verdad: anuncio
   real en dispositivo Android y en iPhone, con Ad Inspector, verificando
   presentación, cierre, ausencia de listeners retenidos y ausencia de fugas
   tras `destroy()`. Esto no lo puede hacer nadie que no tenga los dispositivos
   enfrente.

## Punto de partida

- Rama actual: `main`, con `1.2.1` sin publicar y sin tags de versión.
- Leer antes de escribir: `documentation/fullscreen.md` (el contrato),
  `ios/Classes/TiAdmobUnifiedInterstitialAdProxy.m` y
  `android/src/ti/admob/unified/TiAdmobUnifiedInterstitialAdProxy.java` (la
  plantilla), `tests/contract.test.js` (lo que ya está congelado) y
  `ROADMAP.md`.
- La documentación pública del repositorio está en inglés y hay una prueba que
  lo exige; estas notas internas van en español, como `AUDIT-2026-05.md`.
