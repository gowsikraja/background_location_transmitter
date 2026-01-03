import Foundation

enum HttpMethod: String {
  case get, post, put, patch
}

struct TrackingConfig {

  static var apiUrl: String?
  static var headers: [String: String]?
  static var body: [String: Any]?
  static var method: HttpMethod = .post

  static func configure(from map: [String: Any]) {
    apiUrl = map["url"] as? String
    headers = map["headers"] as? [String: String]
    body = map["body"] as? [String: Any]

    if let methodStr = map["method"] as? String {
      method = HttpMethod(rawValue: methodStr) ?? .post
    }
  }

  static func clear() {
    apiUrl = nil
    headers = nil
    body = nil
    method = .post
  }
}
