import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fortress/flutter_fortress.dart';
import 'package:flutter_fortress/flutter_fortress_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PinningInterceptor', () {
    test('verifyCertificate returns false for empty DER', () {
      final interceptor = PinningInterceptor(pinnedKeys: [
        'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      ]);
      expect(interceptor.verifyCertificate(Uint8List(0)), false);
    });

    test('extracts SPKI from a minimal valid DER structure', () {
      final interceptor = PinningInterceptor(pinnedKeys: []);
      final der = _buildMinimalDer();
      final result = interceptor.verifyCertificate(der);
      expect(result, false);
    });

    test('throws no errors on malformed DER', () {
      final interceptor = PinningInterceptor(pinnedKeys: []);
      expect(interceptor.verifyCertificate([0x00, 0x01, 0x02]), false);
    });
  });

  group('MethodChannelFlutterFortress', () {
    const channel = MethodChannel('flutter_fortress');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        switch (call.method) {
          case 'checkDeviceIntegrity':
            return <String, dynamic>{
              'isRooted': false,
              'isEmulator': false,
              'isTampered': false,
            };
          case 'requestPlayIntegrity':
            return <String, dynamic>{'verified': true, 'token': 'test_token'};
          case 'requestDeviceCheck':
            return true;
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('checkDeviceIntegrity returns correct result', () async {
      final platform = MethodChannelFlutterFortress();
      final result = await platform.checkDeviceIntegrity();
      expect(result.isTrusted, true);
    });

    test('requestPlayIntegrity returns verified', () async {
      final platform = MethodChannelFlutterFortress();
      final result = await platform.requestPlayIntegrity();
      expect(result['verified'], true);
    });

    test('requestDeviceCheck returns true', () async {
      final platform = MethodChannelFlutterFortress();
      final result = await platform.requestDeviceCheck();
      expect(result, true);
    });
  });

  group('FortressGuard initialization', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_fortress'),
        (MethodCall call) async {
          if (call.method == 'checkDeviceIntegrity') {
            return <String, dynamic>{
              'isRooted': false,
              'isEmulator': false,
              'isTampered': false,
            };
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_fortress'), null);
    });

    test('init without onThreat callback does not throw', () async {
      await FortressGuard.init(policy: const FortressPolicy());
    });
  });

  group('FortressHttpClient', () {
    test('create returns Dio instance', () {
      final dio = FortressHttpClient.create(pinnedKeys: []);
      expect(dio, isNotNull);
    });

    test('constructor returns FortressHttpClient', () {
      final client = FortressHttpClient(pinnedKeys: []);
      expect(client, isNotNull);
      expect(client.dio, isNotNull);
    });
  });
}

List<int> _buildMinimalDer() {
  final spki = _buildSequence([
    0x02, 0x03, 0x01, 0x00, 0x01,
  ]);
  final tbsCert = _buildSequence([
    0xA0, 0x03, 0x02, 0x01, 0x02,
    0x02, 0x01, 0x01,
    0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0B, 0x05, 0x00,
    0x30, 0x00,
    0x30, 0x00,
    0x30, 0x00,
    ...spki,
  ]);
  final cert = _buildSequence([...tbsCert, 0x30, 0x00, 0x03, 0x00]);
  return cert;
}

List<int> _buildSequence(List<int> contents) {
  final length = contents.length;
  if (length < 128) {
    return [0x30, length, ...contents];
  }
  return [0x30, 0x81, length, ...contents];
}
