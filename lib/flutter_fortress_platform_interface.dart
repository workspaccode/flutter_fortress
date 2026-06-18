import 'dart:async';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_fortress_method_channel.dart';

class DeviceIntegrityResult {
  final bool isRooted;
  final bool isEmulator;
  final bool isTampered;

  const DeviceIntegrityResult({
    required this.isRooted,
    required this.isEmulator,
    required this.isTampered,
  });

  bool get isTrusted => !isRooted && !isEmulator && !isTampered;

  Map<String, dynamic> toMap() => {
    'isRooted': isRooted,
    'isEmulator': isEmulator,
    'isTampered': isTampered,
  };

  factory DeviceIntegrityResult.fromMap(Map<String, dynamic> map) {
    return DeviceIntegrityResult(
      isRooted: map['isRooted'] as bool? ?? false,
      isEmulator: map['isEmulator'] as bool? ?? false,
      isTampered: map['isTampered'] as bool? ?? false,
    );
  }
}

abstract class FlutterFortressPlatform extends PlatformInterface {
  FlutterFortressPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterFortressPlatform _instance = MethodChannelFlutterFortress();

  static FlutterFortressPlatform get instance => _instance;

  static set instance(FlutterFortressPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<DeviceIntegrityResult> checkDeviceIntegrity() {
    throw UnimplementedError('checkDeviceIntegrity() has not been implemented.');
  }

  Future<void> setExpectedSignatureHash(String hash) {
    throw UnimplementedError('setExpectedSignatureHash() has not been implemented.');
  }

  Future<void> setScreenSecure(bool secure) {
    throw UnimplementedError('setScreenSecure() has not been implemented.');
  }

  Future<Map<String, dynamic>> requestPlayIntegrity({int cloudProjectNumber = 0}) {
    throw UnimplementedError('requestPlayIntegrity() has not been implemented.');
  }

  Future<bool> requestDeviceCheck() {
    throw UnimplementedError('requestDeviceCheck() has not been implemented.');
  }
}
