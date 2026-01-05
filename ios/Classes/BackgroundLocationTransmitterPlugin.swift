import Flutter
import UIKit
import CoreLocation

public class BackgroundLocationTransmitterPlugin: NSObject,
                                                   FlutterPlugin,
                                                   FlutterStreamHandler {

  private static let methodChannelName =
      "background_location_transmitter/methods"
  private static let eventChannelName =
      "background_location_transmitter/events"

  private var eventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {

    let methodChannel = FlutterMethodChannel(
      name: methodChannelName,
      binaryMessenger: registrar.messenger()
    )

    let eventChannel = FlutterEventChannel(
      name: eventChannelName,
      binaryMessenger: registrar.messenger()
    )

    let instance = BackgroundLocationTransmitterPlugin()

    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)

    LocationService.shared.eventHandler = instance
  }


  public func handle(_ call: FlutterMethodCall,
                     result: @escaping FlutterResult) {

    switch call.method {

    case "checkPermission":
      PluginLogger.logPermission("Checking location permissions...")
      let hasPermission = LocationService.shared.hasPermission
      PluginLogger.logPermission("Permission granted: \(hasPermission)")
      result(hasPermission)

    case "isLocationEnabled":
      PluginLogger.logAction("Checking if location services are enabled...")
      let enabled = LocationService.shared.isLocationEnabled
      PluginLogger.logAction("Location services enabled: \(enabled)")
      result(enabled)

    case "startTracking":
      PluginLogger.logService("Request to start tracking received")
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
        return
      }

      TrackingConfig.configure(from: args)
      PluginLogger.logService("Starting LocationService")
      LocationService.shared.start()
      result(nil)

    case "stopTracking":
      PluginLogger.logService("Request to stop tracking received")
      LocationService.shared.stop()
      TrackingConfig.clear()
      PluginLogger.logService("LocationService stopped")
      result(nil)

    case "isTrackingRunning":
      let running = LocationService.shared.isRunning
      PluginLogger.logService("Checking if tracking is running: \(running)")
      result(running)

    case "getCurrentLocation":
      PluginLogger.logAction("Requesting one-time location update...")
      LocationService.shared.getCurrentLocation { data in
        result(data)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }


  public func onListen(withArguments arguments: Any?,
                       eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    PluginLogger.logAction("Flutter execution listening for location updates")
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    PluginLogger.logAction("Flutter execution stopped listening")
    eventSink = nil
    return nil
  }
}

extension BackgroundLocationTransmitterPlugin {
  func emitLocation(_ data: [String: Any]) {
    eventSink?(data)
  }
}
