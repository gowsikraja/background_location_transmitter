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

  /// HTTP headers to include in the request.
  ///
  /// Use this for authentication tokens or content type definitions.
  final Map<String, String> headers;

  /// Base request payload.
  ///
  /// Key-value pairs here will be sent with every request.
  /// Location data is automatically appended by the platform
  /// to this base body.
  final Map<String, dynamic> body;

  LocationApiConfig({
    required this.url,
    required this.headers,
    required this.body,
  });

  /// Converts this configuration into a map suitable for
  /// platform channel transmission.
  Map<String, dynamic> toMap() => {
    'url': url,
    'headers': headers,
    'body': body,
  };
}
