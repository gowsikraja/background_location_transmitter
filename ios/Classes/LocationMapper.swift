import CoreLocation

struct LocationMapper {

  static func map(_ location: CLLocation) -> [String: Any] {
    [
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
      "speed": location.speed,
      "accuracy": location.horizontalAccuracy,
      "timestamp": Int(location.timestamp.timeIntervalSince1970 * 1000)
    ]
  }

  static func placeholderMap(_ location: CLLocation) -> [String: String] {
    [
      "%latitude%": "\(location.coordinate.latitude)",
      "%longitude%": "\(location.coordinate.longitude)",
      "%speed%": "\(location.speed)",
      "%accuracy%": "\(location.horizontalAccuracy)",
      "%timestamp%": "\(Int(location.timestamp.timeIntervalSince1970 * 1000))"
    ]
  }
}
