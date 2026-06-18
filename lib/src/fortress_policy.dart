import 'threat_event.dart';

/// Actions to perform when a threat is identified.
enum ThreatResponse {
  /// Immediately terminate the application.
  kill,

  /// Show a warning dialog to the user.
  warn,

  /// Silently log the threat without user-facing action.
  log,
}

/// Policy configurations defining actions for each monitored threat category.
///
/// Each field maps a [ThreatType] to a [ThreatResponse] action.
/// Defaults mirror the most restrictive security posture.
class FortressPolicy {
  final ThreatResponse onRootDetected;
  final ThreatResponse onEmulatorDetected;
  final ThreatResponse onHookingDetected;
  final ThreatResponse onSSLPinFail;
  final ThreatResponse onScreenCapture;
  final ThreatResponse onTamperDetected;

  const FortressPolicy({
    this.onRootDetected = ThreatResponse.kill,
    this.onEmulatorDetected = ThreatResponse.warn,
    this.onHookingDetected = ThreatResponse.kill,
    this.onSSLPinFail = ThreatResponse.kill,
    this.onScreenCapture = ThreatResponse.log,
    this.onTamperDetected = ThreatResponse.kill,
  });

  /// Get the appropriate response for a specific [ThreatType].
  ThreatResponse getResponseFor(ThreatType type) {
    switch (type) {
      case ThreatType.root:
      case ThreatType.jailbreak:
        return onRootDetected;
      case ThreatType.emulator:
        return onEmulatorDetected;
      case ThreatType.hooking:
        return onHookingDetected;
      case ThreatType.sslPinningMismatch:
        return onSSLPinFail;
      case ThreatType.screenCapture:
        return onScreenCapture;
      case ThreatType.tamper:
        return onTamperDetected;
    }
  }
}
