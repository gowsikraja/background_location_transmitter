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
      result(LocationService.shared.hasPermission)

    case "isLocationEnabled":
      result(LocationService.shared.isLocationEnabled)

    case "startTracking":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
        return
      }

      TrackingConfig.configure(from: args)
      LocationService.shared.start()
      result(nil)

    case "stopTracking":
      LocationService.shared.stop()
      TrackingConfig.clear()
      result(nil)

    case "isTrackingRunning":
      result(LocationService.shared.isRunning)

    case "getCurrentLocation":
      LocationService.shared.getCurrentLocation { data in
        result(data)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }


  public func onListen(withArguments arguments: Any?,
                       eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}

extension BackgroundLocationTransmitterPlugin {
  func emitLocation(_ data: [String: Any]) {
    eventSink?(data)
  }
}
