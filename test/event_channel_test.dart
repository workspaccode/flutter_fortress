import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fortress/flutter_fortress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FortressGuard EventChannel', () {
    late List<ThreatEvent> receivedEvents;

    setUp(() async {
      receivedEvents = [];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter_fortress_events', (message) async {
        // Intercept and do nothing - EventChannel is set up in init
        return null;
      });

      // Set up mock MethodChannel for init's checkDeviceIntegrity
      const methodChannel = MethodChannel('flutter_fortress');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
        if (call.method == 'checkDeviceIntegrity') {
          return <String, dynamic>{
            'isRooted': false,
            'isEmulator': false,
            'isTampered': false,
          };
        }
        return null;
      });

      await FortressGuard.init(
        policy: const FortressPolicy(),
        onThreat: (event) => receivedEvents.add(event),
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter_fortress_events', null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_fortress'), null);
    });

    test('FortressGuard can be instantiated and threatStream is broadcast', () {
      final guard = FortressGuard();
      expect(guard.threatStream, isNotNull);
      expect(guard.threatStream.isBroadcast, true);
    });
  });
}
