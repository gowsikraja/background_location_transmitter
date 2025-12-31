package com.example.background_location_transmitter

import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

/**
 * Android plugin entry point for background_location_transmitter.
 *
 * This class:
 * - Registers method and event channels
 * - Bridges Flutter API calls to native Android implementations
 * - Manages EventChannel lifecycle for location updates
 *
 * Heavy logic is intentionally delegated to dedicated components
 * such as [LocationService] to keep this class lightweight and
 * maintainable.
 */
class BackgroundLocationTransmitterPlugin :
    FlutterPlugin,
    MethodCallHandler,
    EventChannel.StreamHandler {

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(
            binding.binaryMessenger,
            "background_location_transmitter/methods"
        )
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(
            binding.binaryMessenger,
            "background_location_transmitter/events"
        )
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)

        // Clear any stale Flutter references
        LocationService.eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        // Method calls are delegated to platform-specific handlers
        when (call.method) {

            "checkPermission" -> {
                PluginLogger.logPermission("Checking location permissions...")
                val granted = PermissionUtils.checkAndRequestLocationPermission(context)
                PluginLogger.logPermission("Permission granted: $granted")
                result.success(granted)
            }

            "isLocationEnabled" -> {
                PluginLogger.logAction("Checking if location services are enabled...")
                val locationManager =
                    context.getSystemService(Context.LOCATION_SERVICE)
                            as android.location.LocationManager

                val enabled =
                    locationManager.isProviderEnabled(android.location.LocationManager.GPS_PROVIDER) ||
                            locationManager.isProviderEnabled(android.location.LocationManager.NETWORK_PROVIDER)

                PluginLogger.logAction("Location services enabled: $enabled")
                result.success(enabled)
            }

            "startTracking" -> {
                PluginLogger.logService("Request to start tracking received")
                val args = call.arguments as Map<*, *>

                TrackingConfig.apiUrl = args["url"] as? String
                TrackingConfig.headers =
                    (args["headers"] as? Map<*, *>)
                        ?.entries
                        ?.associate { it.key.toString() to it.value.toString() }

                TrackingConfig.baseBody =
                    (args["body"] as? Map<*, *>)
                        ?.entries
                        ?.associate { it.key.toString() to it.value as Any }

                TrackingConfig.debug = (args["debug"] as? Boolean) ?: true
                TrackingConfig.interval = (args["interval"] as? Number)?.toLong() ?: 10000L
                TrackingConfig.httpMethod = (args["method"] as? String) ?: "POST"

                if (!TrackingConfig.isValid()) {
                    PluginLogger.logError("Tracking config is invalid: Missing required fields (URL or headers)")
                    result.error("INVALID_CONFIG", "Tracking config is invalid", null)
                    return
                }

                PluginLogger.logService("Starting LocationService with interval: ${TrackingConfig.interval}ms, method: ${TrackingConfig.httpMethod}")
                val intent = Intent(context, LocationService::class.java)
                ContextCompat.startForegroundService(context, intent)

                ServiceState.saveRunning(context, true)
                result.success(null)
            }

            "stopTracking" -> {
                PluginLogger.logService("Request to stop tracking received")
                context.stopService(Intent(context, LocationService::class.java))
                TrackingConfig.clear()
                ServiceState.saveRunning(context, false)
                PluginLogger.logService("LocationService stopped")
                result.success(null)
            }

            "isTrackingRunning" -> {
                val running = LocationService.isServiceRunning
                PluginLogger.logService("Checking if tracking is running: $running (Live Status)")
                result.success(running)
            }

            "getCurrentLocation" -> {
                PluginLogger.logAction("Requesting one-time location update...")
                LocationUtils.getCurrentLocation(context, result)
            }

            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        // Attach Flutter listener to native service
        PluginLogger.logAction("Flutter execution listening for location updates")
        LocationService.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        // Detach Flutter listener when no longer needed
        PluginLogger.logAction("Flutter execution stopped listening")
        LocationService.eventSink = null
    }
}
