import Foundation
import CoreLocation

class LocationService: NSObject, CLLocationManagerDelegate {

  static let shared = LocationService()

  private let manager = CLLocationManager()
  private(set) var isRunning = false

  weak var eventHandler: BackgroundLocationTransmitterPlugin?

    var hasPermission: Bool {
      let status: CLAuthorizationStatus

      if #available(iOS 14.0, *) {
        status = manager.authorizationStatus
      } else {
        status = CLLocationManager.authorizationStatus()
      }

      return status == .authorizedAlways
    }


  var isLocationEnabled: Bool {
    CLLocationManager.locationServicesEnabled()
  }

  private override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.allowsBackgroundLocationUpdates = true
    manager.pausesLocationUpdatesAutomatically = false
  }

  func start() {
    guard hasPermission else { return }
    isRunning = true
    manager.startUpdatingLocation()
  }

  func stop() {
    isRunning = false
    manager.stopUpdatingLocation()
  }

  func getCurrentLocation(completion: @escaping ([String: Any]?) -> Void) {
    guard hasPermission else {
      completion(nil)
      return
    }

    manager.requestLocation()

    oneTimeCallback = completion
  }

  private var oneTimeCallback: (([String: Any]?) -> Void)?

  // MARK: - CLLocationManagerDelegate

  private var lastUploadTime: Date?

  func locationManager(_ manager: CLLocationManager,
                       didUpdateLocations locations: [CLLocation]) {

    guard let location = locations.last else { return }

    // Throttling Check
    let now = Date()
    if let lastTime = lastUploadTime,
       now.timeIntervalSince(lastTime) < TrackingConfig.interval {
       // Too soon, skip
       return
    }
    lastUploadTime = now

    let data = LocationMapper.map(location)

    // Send to Flutter if active
    eventHandler?.emitLocation(data)

    // Upload if configured
    LocationUploader.upload(location)

    // One-time request
    oneTimeCallback?(data)
    oneTimeCallback = nil
  }

  func locationManager(_ manager: CLLocationManager,
                       didFailWithError error: Error) {
    oneTimeCallback?(nil)
    oneTimeCallback = nil
  }
}
