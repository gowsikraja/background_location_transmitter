/// Runtime initialization configuration
/// for background location tracking.
///
/// This config controls non-API behaviors
/// such as logging and update intervals.
class TrackingConfig {
  /// Enables or disables all plugin logs.
  /// Should be disabled in production builds.
  /// Defaults to true.
  final bool debug;

  /// Minimum time between location updates.
  /// Enforced at both Flutter and native layers.
  /// Should be at least 5 seconds.
  /// Defaults to 10 seconds.
  final Duration locationUpdateInterval;

  const TrackingConfig({
    this.debug = true,
    this.locationUpdateInterval = const Duration(seconds: 10),
  });

  /// Serializes config for native platform usage.
  Map<String, dynamic> toMap() {
    return {'debug': debug, 'interval': locationUpdateInterval.inMilliseconds};
  }
}
