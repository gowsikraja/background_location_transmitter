import Foundation

enum HttpMethod: String {
  case get, post, put, patch
}

struct TrackingConfig {

  static var apiUrl: String?
  static var headers: [String: String]?
  static var body: [String: Any]?
  static var method: HttpMethod = .post
  static var debug: Bool = true
  static var interval: TimeInterval = 10.0 // Seconds

  static func configure(from map: [String: Any]) {
    apiUrl = map["url"] as? String
    headers = map["headers"] as? [String: String]
    body = map["body"] as? [String: Any]

    if let methodStr = map["method"] as? String {
      method = HttpMethod(rawValue: methodStr) ?? .post
    }

    if let debugVal = map["debug"] as? Bool {
      debug = debugVal
    } else {
        debug = true
    }

    if let intervalMs = map["interval"] as? Double {
        interval = intervalMs / 1000.0
    } else {
        interval = 10.0
    }
  }

  static func clear() {
    apiUrl = nil
    headers = nil
    body = nil
    method = .post
    debug = true
    interval = 10.0
  }
}
