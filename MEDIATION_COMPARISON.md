# Mediation status

The 1.2.0 core artifact intentionally includes only Google Mobile Ads and User
Messaging Platform.

The previous 1.1.0 bundle included Meta, InMobi, AppLovin, IronSource, Unity,
and Liftoff/Vungle with different platform versions. No local production
consumer was found, and the only local test consumer merely displayed adapter
availability. Those SDKs were therefore removed from the core to reduce binary
size, privacy declarations, initialization work, and maintenance surface.

Compatibility methods remain. They report unavailable/no-op behavior in the
core-only distribution. Android's legacy consent setters still use reflection
when a consumer separately supplies an optional network SDK; the module itself
does not add one. A future mediation offering should be an optional
distribution with:

- explicit consumer demand;
- independently current adapters on each platform;
- documented privacy manifests and SKAdNetwork requirements;
- device tests and Ad Inspector evidence;
- no unsupported revenue claims.

The JavaScript ad API should remain unchanged if optional mediation is added.
