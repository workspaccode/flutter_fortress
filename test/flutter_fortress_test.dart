import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fortress/flutter_fortress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FortressGuard policy checks', () {
    test('Policy returns correct response types', () {
      const policy = FortressPolicy(
        onRootDetected: ThreatResponse.kill,
        onEmulatorDetected: ThreatResponse.warn,
        onSSLPinFail: ThreatResponse.kill,
      );

      expect(policy.getResponseFor(ThreatType.root), ThreatResponse.kill);
      expect(policy.getResponseFor(ThreatType.jailbreak), ThreatResponse.kill);
      expect(policy.getResponseFor(ThreatType.emulator), ThreatResponse.warn);
      expect(policy.getResponseFor(ThreatType.hooking), ThreatResponse.kill);
      expect(policy.getResponseFor(ThreatType.sslPinningMismatch), ThreatResponse.kill);
      expect(policy.getResponseFor(ThreatType.screenCapture), ThreatResponse.log);
      expect(policy.getResponseFor(ThreatType.tamper), ThreatResponse.kill);
    });

    test('Default policy values', () {
      const policy = FortressPolicy();
      expect(policy.onRootDetected, ThreatResponse.kill);
      expect(policy.onEmulatorDetected, ThreatResponse.warn);
      expect(policy.onHookingDetected, ThreatResponse.kill);
      expect(policy.onSSLPinFail, ThreatResponse.kill);
      expect(policy.onScreenCapture, ThreatResponse.log);
      expect(policy.onTamperDetected, ThreatResponse.kill);
    });

    test('ThreatEvent constructor sets timestamp automatically', () {
      final event = ThreatEvent(
        type: ThreatType.hooking,
        message: 'Frida hooks detected',
      );

      expect(event.type, ThreatType.hooking);
      expect(event.message, 'Frida hooks detected');
      expect(event.timestamp, isNotNull);
    });
  });
}
