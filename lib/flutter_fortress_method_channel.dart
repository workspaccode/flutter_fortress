import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_fortress_platform_interface.dart';

/// An implementation of [FlutterFortressPlatform] that uses method channels.
class MethodChannelFlutterFortress extends FlutterFortressPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_fortress');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
