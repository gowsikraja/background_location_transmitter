import 'package:background_location_transmitter/src/http_method.dart';

/// Represents a single location snapshot.
///
/// This model contains the geographic position along with
/// metadata such as accuracy and speed.
class LocationData {
  /// Latitude in degrees.
  final double? latitude;

  /// Longitude in degrees.
  final double? longitude;

  /// Speed in meters per second.
  final double? speed;

  /// Estimated horizontal accuracy in meters.
  final double? accuracy;

  /// Time at which the location was recorded.
  final DateTime? timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.accuracy,
    required this.timestamp,
  });

  /// Creates a [LocationData] instance from a platform map.
  factory LocationData.fromMap(Map<dynamic, dynamic> map) {
    return LocationData(
      latitude: map['latitude'],
      longitude: map['longitude'],
      speed: map['speed'],
      accuracy: map['accuracy'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}

/// Configuration describing how location data is transmitted.
///
/// The native platform uses this configuration to construct
/// network requests when sending location updates.
class LocationApiConfig {
  /// Target API endpoint URL.
  ///
  /// This must be a full, valid URL (e.g., https://api.example.com/location).
  final String url;

  /// HTTP method to use for requests.
  ///
  /// Defaults to POST.
  final HttpMethod method;

  /// HTTP headers to include in the request.
  ///
  /// Use this for authentication tokens or content type definitions.
  final Map<String, String> headers;

  /// The HTTP request body.
  ///
  /// This map corresponds to the JSON payload sent to the server.
  /// The plugin automatically appends the following location fields
  /// to this map at runtime:
  /// - `latitude` (double)
  /// - `longitude` (double)
  /// - `speed` (double)
  /// - `accuracy` (double)
  /// - `timestamp` (int, milliseconds since epoch)
  ///
  /// **Dynamic Placeholders**:
  /// You can customize the request structure by using the following
  /// placeholders in your [url] or [body] values. If placeholders
  /// are detected in the [body], the auto-append behavior is disabled,
  /// giving you full control over the payload schema.
  /// - `%latitude%`
  /// - `%longitude%`
  /// - `%speed%`
  /// - `%accuracy%`
  /// - `%timestamp%`
  ///
  /// Example:
  /// ```dart
  /// body: {
  ///   'user_id': '123',
  ///   'loc': {
  ///     'lat': '%latitude%',
  ///     'lng': '%longitude%'
  ///   }
  /// }
  /// ```
  final Map<String, dynamic>? body;

  LocationApiConfig({
    required this.url,
    required this.headers,
    this.body,
    this.method = HttpMethod.post,
  });

  /// Converts this configuration into a map suitable for
  /// platform channel transmission.
  Map<String, dynamic> toMap() => {
    'url': url,
    'headers': headers,
    'body': body,
    'method': method.value,
  };
}
