# Dependency inventory

This file is the source-of-truth inventory for the vendored iOS binaries and
the Maven dependencies used by the Android module.

## iOS vendored XCFrameworks

| Framework | Version | Official archive | Official SHA-1 | Archive SHA-256 | XCFramework tree SHA-256 |
|---|---:|---|---|---|---|
| GoogleMobileAds.xcframework | 13.7.0 | https://dl.google.com/googleadmobadssdk/googlemobileadssdkios.zip | `b16613a6bc2410be7f5d6e586470ba20fd1b83c3` | `cc971f9c5e197bba82262424c7b5abcf8d7b895bfc8e59d474af696f28bebd59` | `86620aa1581fd67a513cac90582415fcb320a11f7d9e2cd7484b198760d9a188` |
| UserMessagingPlatform.xcframework | 3.1.0 | https://dl.google.com/googleadmobadssdk/googleusermessagingplatform.zip | `c033b599479d618afd79cbf947dc9dbb21d4fc4a` | `02b6b1925be8a6cfc294478c1a6bb1dd4de70cd9e4f31cbbfb789ab4de7b2955` | `a9817dd1b5288b6c8c6858e0a689ffd7af0d7ad85cc51628256cbd1ad93f5fdc` |

The tree checksum is calculated from the sorted list of relative file paths
and the SHA-256 of every file in the XCFramework:

```sh
find . -type f -print0 | LC_ALL=C sort -z | xargs -0 shasum -a 256 |
  shasum -a 256
```

## Android Maven dependencies

| Coordinate | Version |
|---|---:|
| `com.google.android.gms:play-services-ads` | 25.4.0 |
| `com.google.android.ump:user-messaging-platform` | 4.0.0 |

The core artifact intentionally contains no third-party mediation adapters.
