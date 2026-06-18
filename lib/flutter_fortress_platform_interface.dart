import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_fortress_method_channel.dart';

abstract class FlutterFortressPlatform extends PlatformInterface {
  /// Constructs a FlutterFortressPlatform.
  FlutterFortressPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterFortressPlatform _instance = MethodChannelFlutterFortress();

  /// The default instance of [FlutterFortressPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterFortress].
  static FlutterFortressPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterFortressPlatform] when
  /// they register themselves.
  static set instance(FlutterFortressPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
