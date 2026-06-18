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
