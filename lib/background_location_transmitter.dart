import 'package:background_location_transmitter/background_location_transmitter.dart';

import 'src/method_channel_impl.dart';
import 'src/models.dart';

export 'src/models.dart';
export 'src/tracking_config.dart';

/// Provides background location tracking and transmission capabilities.
///
/// This plugin uses native foreground services to:
/// - Track device location reliably in the background
/// - Transmit location data to a configured backend endpoint
/// - Deliver live location updates to Flutter when the app is active
///
/// The background service operates independently of the Flutter engine.
/// Location tracking continues even when the app is closed or killed,
/// until explicitly stopped by the application.
class BackgroundLocationTransmitter {
  BackgroundLocationTransmitter._internal();

  /// Singleton instance of the plugin.
  static final BackgroundLocationTransmitter instance =
      BackgroundLocationTransmitter._internal();

  final MethodChannelImpl _platform = MethodChannelImpl();

  /// Checks and requests the required location permissions.
  ///
  /// Returns `true` if all required permissions are already granted.
  /// If permissions are missing, the system permission dialog
  /// will be displayed.
  Future<bool> checkPermission() => _platform.checkPermission();

  /// Returns whether location services are enabled on the device.
  ///
  /// This checks the system-level location state (GPS / network),
  /// not application permissions.
  Future<bool> isLocationEnabled() => _platform.isLocationEnabled();

  /// Starts background location tracking and transmission.
  ///
  /// The provided [config] defines how location data is sent
  /// to the backend service. The native service automatically
  /// appends location information to the request payload.
  ///
  /// The optional [trackingConfig] allows customizing behavior
  /// such as debug logging and update intervals.
  ///
  /// Calling this method multiple times has no effect if the
  /// service is already running.
  Future<void> startTracking(
    LocationApiConfig config, {
    TrackingConfig trackingConfig = const TrackingConfig(),
  }) {
    if (trackingConfig.locationUpdateInterval < const Duration(seconds: 5)) {
      throw ArgumentError(
        'Location update interval must be at least 5 seconds',
      );
    }
    return _platform.startTracking(config, trackingConfig);
  }

  /// Stops background location tracking and transmission.
  ///
  /// Once stopped, no further location updates will be generated
  /// or transmitted until [startTracking] is called again.
  Future<void> stopTracking() => _platform.stopTracking();

  /// Returns whether the background tracking service is currently active.
  ///
  /// This value reflects the native service state and remains accurate
  /// even if the Flutter app was restarted.
  Future<bool> isTrackingRunning() => _platform.isTrackingRunning();

  /// Stream of live location updates.
  ///
  /// This stream emits values only while the Flutter engine is active.
  /// Background tracking continues regardless of stream listeners.
  Stream<LocationData> get locationStream => _platform.locationStream;

  /// Fetches the device’s current location once.
  ///
  /// This does not start background tracking and does not affect
  /// the running tracking service, if any.
  Future<LocationData?> getCurrentLocation() => _platform.getCurrentLocation();
}
