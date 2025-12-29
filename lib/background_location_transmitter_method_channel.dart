import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'background_location_transmitter_platform_interface.dart';

/// An implementation of [BackgroundLocationTransmitterPlatform] that uses method channels.
class MethodChannelBackgroundLocationTransmitter extends BackgroundLocationTransmitterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('background_location_transmitter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
