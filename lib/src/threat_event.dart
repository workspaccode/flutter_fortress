/// Threat types monitored by Flutter Fortress.
enum ThreatType {
  root,
  jailbreak,
  emulator,
  hooking,
  sslPinningMismatch,
  screenCapture,
  tamper,
}

/// Event representing a detected threat.
class ThreatEvent {
  final ThreatType type;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  ThreatEvent({
    required this.type,
    required this.message,
    DateTime? timestamp,
    this.details,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'ThreatEvent(type: $type, message: $message, timestamp: $timestamp, details: $details)';
  }
}
