import Foundation
import CoreLocation

class LocationUploader {

  static func upload(_ location: CLLocation) {
    guard let templateUrl = TrackingConfig.apiUrl else { return }

    let placeholders = LocationMapper.placeholderMap(location)

    let urlString = replace(templateUrl, placeholders)
    guard let url = URL(string: urlString) else { return }

    var request = URLRequest(url: url)
    request.httpMethod = TrackingConfig.method.rawValue.uppercased()

    TrackingConfig.headers?.forEach {
      request.addValue($0.value, forHTTPHeaderField: $0.key)
    }

    if let body = TrackingConfig.body,
       TrackingConfig.method != .get {

      let replacedBody = replaceBody(body, placeholders)
      request.httpBody = try? JSONSerialization.data(withJSONObject: replacedBody)
    }

    URLSession.shared.dataTask(with: request).resume()
  }

  private static func replace(_ template: String,
                              _ values: [String: String]) -> String {
    var result = template
    values.forEach { result = result.replacingOccurrences(of: $0.key, with: $0.value) }
    return result
  }

  private static func replaceBody(_ body: [String: Any],
                                  _ values: [String: String]) -> [String: Any] {
    var result = [String: Any]()

    body.forEach { key, value in
      if let str = value as? String {
        var replaced = str
        values.forEach {
          replaced = replaced.replacingOccurrences(of: $0.key, with: $0.value)
        }
        result[key] = replaced
      } else {
        result[key] = value
      }
    }
    return result
  }
}
