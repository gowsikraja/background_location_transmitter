/// Defines supported HTTP methods for transmitting
/// location data to a backend service.
///
/// Only idempotent and server-safe mutation methods
/// are allowed for production reliability.
enum HttpMethod {
  post,
  put,
  patch;

  /// Returns the HTTP method as an uppercase string
  /// to be passed across platform channels.
  String get value {
    switch (this) {
      case HttpMethod.post:
        return 'POST';
      case HttpMethod.put:
        return 'PUT';
      case HttpMethod.patch:
        return 'PATCH';
    }
  }
}
