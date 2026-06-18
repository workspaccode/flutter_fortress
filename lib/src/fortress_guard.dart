import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import '../flutter_fortress_platform_interface.dart';
import 'threat_event.dart';
import 'fortress_policy.dart';
import 'utils/fortress_logger.dart';

class FortressGuard {
  static const EventChannel _eventChannel = EventChannel('flutter_fortress_events');

  static final FortressGuard _instance = FortressGuard._internal();
  factory FortressGuard() => _instance;
  FortressGuard._internal();

  FortressPolicy _policy = const FortressPolicy();
  Function(ThreatEvent)? _onThreatCallback;
  final StreamController<ThreatEvent> _threatController = StreamController<ThreatEvent>.broadcast();

  Stream<ThreatEvent> get threatStream => _threatController.stream;

  static Future<void> init({
    required FortressPolicy policy,
    Function(ThreatEvent)? onThreat,
  }) async {
    _instance._policy = policy;
    _instance._onThreatCallback = onThreat;
    _instance._startListening();
    FortressLogger.info('FortressGuard initialized.');

    await checkDeviceIntegrity();
  }

  void _startListening() {
    _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          final typeStr = event['type'] as String;
          final message = event['message'] as String? ?? 'Security threat triggered';
          final details = Map<String, dynamic>.from(event['details'] as Map? ?? {});

          ThreatType? type;
          for (final t in ThreatType.values) {
            if (t.name == typeStr) {
              type = t;
              break;
            }
          }

          if (type != null) {
            final threatEvent = ThreatEvent(
              type: type,
              message: message,
              details: details,
            );
            handleThreat(threatEvent);
          }
        }
      },
      onError: (dynamic error) {
        FortressLogger.error('Error in threat event stream', error);
      },
    );
  }

  static Future<Map<String, dynamic>> requestPlayIntegrity({
    int cloudProjectNumber = 0,
  }) async {
    try {
      return await FlutterFortressPlatform.instance.requestPlayIntegrity(
        cloudProjectNumber: cloudProjectNumber,
      );
    } on PlatformException catch (e) {
      FortressLogger.error('Play Integrity check failed', e);
    }
    return {'verified': false, 'error': 'Platform call failed'};
  }

  static Future<bool> requestDeviceCheck() async {
    try {
      return await FlutterFortressPlatform.instance.requestDeviceCheck();
    } on PlatformException catch (e) {
      FortressLogger.error('DeviceCheck failed', e);
    }
    return false;
  }

  static Future<DeviceIntegrityResult> checkDeviceIntegrity() async {
    try {
      final status = await FlutterFortressPlatform.instance.checkDeviceIntegrity();

      if (status.isRooted) {
        _instance.handleThreat(ThreatEvent(
          type: Platform.isAndroid ? ThreatType.root : ThreatType.jailbreak,
          message: 'Device security check failed: Root/Jailbreak detected.',
        ));
      }
      if (status.isEmulator) {
        _instance.handleThreat(ThreatEvent(
          type: ThreatType.emulator,
          message: 'Device security check failed: Emulator environment detected.',
        ));
      }
      if (status.isTampered) {
        _instance.handleThreat(ThreatEvent(
          type: ThreatType.tamper,
          message: 'Device security check failed: App signature tamper detected.',
        ));
      }

      return status;
    } on PlatformException catch (e) {
      FortressLogger.error('Failed checking device integrity', e);
    }
    return const DeviceIntegrityResult(
      isRooted: false,
      isEmulator: false,
      isTampered: false,
    );
  }

  void handleThreat(ThreatEvent event) {
    FortressLogger.warn('Security threat triggered: ${event.type.name} - ${event.message}');
    _threatController.add(event);
    _onThreatCallback?.call(event);

    final response = _policy.getResponseFor(event.type);
    if (response == ThreatResponse.kill) {
      FortressLogger.error('Threat policy dictates termination. Killing application.');
      kill();
    }
  }

  static void kill() {
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    Future.delayed(const Duration(milliseconds: 200), () {
      exit(0);
    });
  }
}
