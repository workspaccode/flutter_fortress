## 0.2.0

* **SECURITY:** iOS tamper detection with IntegrityChecker (SHA-256 executable hash).
* **SECURITY:** INTERNET + ACCESS_NETWORK_STATE permissions for port scanning.
* **SECURITY:** Play Integrity API (Android) integration.
* **SECURITY:** DeviceCheck (iOS) integration.
* **SECURITY:** Anti-debug detection (Android TracerPid, iOS sysctl/ptrace).
* **SECURITY:** Magisk Hide / Zygisk detection.
* **SECURITY:** Expanded Frida detection (5 ports, process scanning, LD_PRELOAD).
* **SECURITY:** String obfuscation in native code (XOR encoding).
* **SECURITY:** ProGuard/R8 rules for Android release builds.
* **BREAKING:** `DeviceIntegrityStatus` replaced with `DeviceIntegrityResult` from platform interface.
* **API:** `FortressHttpClient` now has constructor API (`FortressHttpClient(pinnedKeys: ...)`).
* **API:** Expanded `FlutterFortressPlatform` with all security methods.
* **API:** `setExpectedSignatureHash` now works on iOS as well.
* **API:** `requestPlayIntegrity()` and `requestDeviceCheck()` methods.
* **TEST:** Added SSL pinning unit tests (SPKI extraction, DER parsing).
* **TEST:** Added EventChannel mock test.
* **TEST:** Added platform interface method tests.
* **CI:** GitHub Actions workflow (analyze, test, build, pana).
* **DOCS:** Updated README with all new API methods.
* **CONFIG:** Privacy manifest enabled in podspec.
* **CONFIG:** MIT license file added.
* **CONFIG:** pub.dev metadata (repository, issues, topics).

## 0.1.0

* Initial release of Flutter Fortress RASP security plugin.
* SSL Pinning with SPKI SHA-256 hash verification via Dio interceptor.
* Root / Jailbreak detection (Android binaries, iOS sandbox integrity).
* Emulator detection (Android build properties, iOS simulator check).
* Anti-Frida & anti-hooking detection (port scanning, /proc/self/maps, dyld).
* Anti-screenshot & screen recording protection (FLAG_SECURE, UITextField overlay).
* App integrity & tamper detection (APK/IPA signature hash verification).
* FortressGuard singleton with configurable threat policy and event stream.
* SecureScreen widget for protecting sensitive UI content.
* FortressMonitor debug overlay with real-time threat dashboard.
* Full Kotlin (Android) and Swift (iOS) native implementations.
* Complete example app demonstrating all 6 features.
* Comprehensive README with API documentation and threat table.
