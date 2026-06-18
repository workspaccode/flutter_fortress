# Flutter Fortress 🛡️

[![pub package](https://img.shields.io/pub/v/flutter_fortress.svg)](https://pub.dev/packages/flutter_fortress)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.0-blue.svg)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-Kotlin-purple.svg)](https://kotlinlang.org)
[![iOS](https://img.shields.io/badge/iOS-Swift-orange.svg)](https://developer.apple.com/swift)

A production-ready Runtime Application Self-Protection (RASP) security plugin for Flutter apps. Adds multiple security layers natively to make your app a self-defending black box at runtime.

---

## Features

| Feature | Description | Android | iOS |
|---------|-------------|:-------:|:---:|
| **SSL Pinning** | Public Key Hash (SHA-256) pinning via Dio interceptor | ✅ | ✅ |
| **Root / Jailbreak Detection** | Binary scanning, system props, sandbox integrity | ✅ | ✅ |
| **Emulator Detection** | Hardware model, build fingerprint, environment checks | ✅ | ✅ |
| **Anti-Frida & Anti-Hooking** | Port scanning, /proc/self/maps, dyld library inspection | ✅ | ✅ |
| **Anti-Screenshot & Recording** | FLAG_SECURE (Android) / UITextField overlay (iOS) | ✅ | ✅ |
| **App Integrity & Tamper Detection** | Runtime APK/IPA signature hash verification | ✅ | ✅ |
| **Fortress Monitor** | Real-time threat status dashboard overlay (debug mode) | ✅ | ✅ |

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_fortress:
    path: path/to/flutter_fortress
```

Then run:

```bash
flutter pub get
```

---

## Quick Start

### 1. Initialize FortressGuard

```dart
import 'package:flutter/material.dart';
import 'package:flutter_fortress/flutter_fortress.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FortressGuard.init(
    policy: const FortressPolicy(
      onRootDetected: ThreatResponse.kill,
      onHookingDetected: ThreatResponse.kill,
      onEmulatorDetected: ThreatResponse.warn,
      onSSLPinFail: ThreatResponse.kill,
      onScreenCapture: ThreatResponse.log,
      onTamperDetected: ThreatResponse.kill,
    ),
    onThreat: (event) {
      // Send to your analytics/SIEM
      print('Threat: ${event.type.name} | ${event.message}');
    },
  );

  runApp(MyApp());
}
```

### 2. SSL Pinning

```dart
import 'package:dio/dio.dart';
import 'package:flutter_fortress/flutter_fortress.dart';

final dio = FortressHttpClient.create(
  pinnedKeys: [
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
  ],
);

final response = await dio.get('https://api.example.com/data');
```

### 3. Screen Protection

Wrap sensitive widgets to block screenshots and screen recording:

```dart
SecureScreen(
  child: Column(
    children: [
      Text('Confidential banking info'),
      CreditCardWidget(...),
    ],
  ),
)
```

### 4. Device Integrity Check

```dart
final status = await FortressGuard.checkDeviceIntegrity();

if (status.isRooted) {
  // Handle rooted device
}
if (status.isEmulator) {
  // Handle emulator
}
if (!status.isTrusted) {
  FortressGuard.kill();
}
```

### 5. Listen to Threat Events

```dart
FortressGuard().threatStream.listen((event) {
  switch (event.type) {
    case ThreatType.root:
      // Handle root detection
      break;
    case ThreatType.hooking:
      // Handle Frida/hooking
      break;
    case ThreatType.sslPinningMismatch:
      // Handle SSL pin failure
      break;
    // ... other threat types
  }
});
```

### 6. Fortress Monitor (Debug Overlay)

```dart
FortressMonitor(
  child: MyApp(),
)
```

---

## API Reference

### FortressGuard

| Method | Return | Description |
|--------|--------|-------------|
| `init(policy, onThreat)` | `Future<void>` | Initializes all detection modules and starts monitoring |
| `checkDeviceIntegrity()` | `Future<DeviceIntegrityStatus>` | Manually checks root, jailbreak, emulator, and tamper status |
| `kill()` | `void` | Wipes session data and terminates the application |
| `threatStream` | `Stream<ThreatEvent>` | Broadcast stream of detected threats |

### FortressPolicy

| Parameter | Default | Description |
|-----------|---------|-------------|
| `onRootDetected` | `ThreatResponse.kill` | Response when root/jailbreak is detected |
| `onEmulatorDetected` | `ThreatResponse.warn` | Response when emulator environment is detected |
| `onHookingDetected` | `ThreatResponse.kill` | Response when Frida/hooking is detected |
| `onSSLPinFail` | `ThreatResponse.kill` | Response when SSL pin validation fails |
| `onScreenCapture` | `ThreatResponse.log` | Response when screen capture is attempted |
| `onTamperDetected` | `ThreatResponse.kill` | Response when app tampering is detected |

### ThreatType

| Value | Description |
|-------|-------------|
| `root` | Android rooted device detected |
| `jailbreak` | iOS jailbroken device detected |
| `emulator` | Running in emulator/simulator environment |
| `hooking` | Frida or hooking framework detected |
| `sslPinningMismatch` | SSL certificate pin validation failed |
| `screenCapture` | Screenshot or screen recording attempted |
| `tamper` | App signature/tamper detected |

### FortressHttpClient

```dart
static Dio create({
  required List<String> pinnedKeys,
  bool allowBadCertificates = false,
})
```

### SecureScreen

```dart
SecureScreen({
  required Widget child,
})
```

### FortressMonitor

```dart
FortressMonitor({
  required Widget child,
  bool enableInRelease = false,
})
```

---

## Architecture

```
flutter_fortress/
├── lib/
│   ├── flutter_fortress.dart              # Main export barrel
│   └── src/
│       ├── fortress_guard.dart             # Central controller singleton
│       ├── fortress_policy.dart            # Policy config model
│       ├── threat_event.dart               # ThreatEvent enum + model
│       ├── ssl_pinning/
│       │   ├── fortress_http_client.dart   # Dio factory with pinning
│       │   └── pinning_interceptor.dart    # SPKI hash verification
│       ├── secure_screen/
│       │   ├── secure_screen.dart          # Widget wrapper
│       │   └── fortress_monitor.dart       # Debug overlay
│       └── utils/
│           └── fortress_logger.dart        # Logging utility
├── android/src/main/kotlin/.../
│   ├── FlutterFortressPlugin.kt            # Plugin entry point
│   ├── RootDetector.kt                     # Root detection
│   ├── FridaDetector.kt                    # Anti-Frida checks
│   ├── EmulatorDetector.kt                 # Emulator detection
│   └── IntegrityChecker.kt                 # Signature verification
├── ios/flutter_fortress/Sources/.../
│   ├── FlutterFortressPlugin.swift         # Plugin entry point
│   ├── RootDetector.swift                  # Jailbreak detection
│   ├── FridaDetector.swift                 # Anti-Frida checks
│   └── ScreenProtection.swift              # Screenshot prevention
└── example/                                # Full working demo app
```

---

## Security Notes

- All native detection logic runs via **MethodChannel** (not pure Dart) to prevent hooking bypass
- String constants in native code are obfuscation-friendly
- The package is **fully offline-capable** — no internet access required
- Detection runs continuously in the background via **EventChannel**
- Frida detection scans ports 27042/27043, /proc/self/maps, and loaded dylibs every 3 seconds

---

## Platform Requirements

| Platform | Minimum Version |
|----------|----------------|
| Android | API 21 (Android 5.0) |
| iOS | 12.0 |
| Flutter | 3.0+ |
| Dart | 3.0+ |

---

## License

MIT License. See [LICENSE](LICENSE) for details.
