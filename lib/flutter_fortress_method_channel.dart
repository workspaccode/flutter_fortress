import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_fortress_platform_interface.dart';

class MethodChannelFlutterFortress extends FlutterFortressPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_fortress');

  @override
  Future<String?> getPlatformVersion() async {
    return await methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Future<DeviceIntegrityResult> checkDeviceIntegrity() async {
    final result = await methodChannel.invokeMethod<Map>('checkDeviceIntegrity');
    if (result != null) {
      return DeviceIntegrityResult.fromMap(Map<String, dynamic>.from(result));
    }
    return const DeviceIntegrityResult(
      isRooted: false,
      isEmulator: false,
      isTampered: false,
    );
  }

  @override
  Future<void> setExpectedSignatureHash(String hash) async {
    await methodChannel.invokeMethod('setExpectedSignatureHash', {'hash': hash});
  }

  @override
  Future<void> setScreenSecure(bool secure) async {
    await methodChannel.invokeMethod('setScreenSecure', {'secure': secure});
  }

  @override
  Future<Map<String, dynamic>> requestPlayIntegrity({int cloudProjectNumber = 0}) async {
    final result = await methodChannel.invokeMethod<Map>(
      'requestPlayIntegrity',
      {'cloudProjectNumber': cloudProjectNumber},
    );
    if (result != null) {
      return Map<String, dynamic>.from(result);
    }
    return {'verified': false, 'error': 'Platform call failed'};
  }

  @override
  Future<bool> requestDeviceCheck() async {
    final result = await methodChannel.invokeMethod<bool>('requestDeviceCheck');
    return result == true;
  }
}
