import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'background_location_transmitter_method_channel.dart';

abstract class BackgroundLocationTransmitterPlatform extends PlatformInterface {
  /// Constructs a BackgroundLocationTransmitterPlatform.
  BackgroundLocationTransmitterPlatform() : super(token: _token);

  static final Object _token = Object();

  static BackgroundLocationTransmitterPlatform _instance = MethodChannelBackgroundLocationTransmitter();

  /// The default instance of [BackgroundLocationTransmitterPlatform] to use.
  ///
  /// Defaults to [MethodChannelBackgroundLocationTransmitter].
  static BackgroundLocationTransmitterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BackgroundLocationTransmitterPlatform] when
  /// they register themselves.
  static set instance(BackgroundLocationTransmitterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
