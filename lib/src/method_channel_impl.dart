import 'dart:async';
import 'package:flutter/services.dart';
import 'models.dart';

/// Internal platform communication layer for
/// `background_location_transmitter`.
///
/// This class is responsible for:
/// - Invoking platform-specific methods via [MethodChannel]
/// - Receiving continuous location updates via [EventChannel]
///
/// This layer is intentionally kept private and should not be
/// exposed directly to plugin consumers. All public interaction
/// must go through the high-level API in
/// `background_location_transmitter.dart`.
class MethodChannelImpl {
  static const MethodChannel _methodChannel = MethodChannel(
    'background_location_transmitter/methods',
  );

  static const EventChannel _eventChannel = EventChannel(
    'background_location_transmitter/events',
  );

  Stream<LocationData>? _locationStream;

  /// Requests required runtime permissions on the platform side.
  ///
  /// Returns `true` if permissions are already granted or were
  /// granted by the user.
  Future<bool> checkPermission() async =>
      await _methodChannel.invokeMethod<bool>('checkPermission') ?? false;

  /// Checks whether system-level location services are enabled.
  ///
  /// This does not check application permissions.
  Future<bool> isLocationEnabled() async =>
      await _methodChannel.invokeMethod<bool>('isLocationEnabled') ?? false;

  /// Starts background location tracking using the provided [config].
  ///
  /// The configuration is forwarded to the native platform,
  /// where it is stored and used for location transmission.
  Future<void> startTracking(LocationApiConfig config) async =>
      await _methodChannel.invokeMethod('startTracking', config.toMap());

  /// Stops background location tracking and transmission.
  Future<void> stopTracking() async =>
      await _methodChannel.invokeMethod('stopTracking');

  /// Returns whether the native background service is currently running.
  Future<bool> isTrackingRunning() async =>
      await _methodChannel.invokeMethod<bool>('isTrackingRunning') ?? false;

  /// Stream of live location updates from the native platform.
  ///
  /// Events are emitted only while the Flutter engine is active.
  /// Background tracking continues regardless of stream listeners.
  Stream<LocationData> get locationStream {
    _locationStream ??= _eventChannel.receiveBroadcastStream().map(
      (event) => LocationData.fromMap(event),
    );
    return _locationStream!;
  }

  /// Retrieves a one-time snapshot of the device’s current location.
  ///
  /// This does not start background tracking and does not affect
  /// any existing background service.
  Future<LocationData?> getCurrentLocation() async {
    final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'getCurrentLocation',
    );
    return result == null ? null : LocationData.fromMap(result);
  }
}
