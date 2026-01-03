import Flutter
import UIKit

public class BackgroundLocationTransmitterPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.example.location/channel",
      binaryMessenger: registrar.messenger()
    )

    let instance = BackgroundLocationTransmitterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    switch call.method {

    case "startTracking":
      result(
        FlutterError(
          code: "UNSUPPORTED",
          message: "iOS support is under development",
          details: nil
        )
      )

    case "stopTracking":
      result(nil)

    case "isTrackingRunning":
      result(false)

    case "getCurrentLocation":
      result(
        FlutterError(
          code: "UNSUPPORTED",
          message: "iOS support is under development",
          details: nil
        )
      )

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
