package com.example.background_location_transmitter

import android.content.Context
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
        // (implementation omitted here for brevity)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        // Attach Flutter listener to native service
        LocationService.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        // Detach Flutter listener when no longer needed
        LocationService.eventSink = null
    }
}
