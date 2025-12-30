package com.example.background_location_transmitter

import android.util.Log

/**
 * Handles all internal logging for the plugin.
 *
 * Logs are only printed if [TrackingConfig.debug] is true.
 * Each log message is prefixed with a specific icon to
 * indicate the type of event.
 */
object PluginLogger {

    private const val TAG = "BackgroundLocation"

    fun log(message: String) {
        if (TrackingConfig.debug) {
            Log.d(TAG, message)
        }
    }

    fun logError(message: String, throwable: Throwable? = null) {
        if (TrackingConfig.debug) {
            Log.e(TAG, "❌ $message", throwable)
        }
    }

    fun logAction(message: String) {
        log("⚡ $message")
    }

    fun logLocation(message: String) {
        log("📍 $message")
    }

    fun logPermission(message: String) {
        log("🛡️ $message")
    }

    fun logService(message: String) {
        log("⚙️ $message")
    }
}
