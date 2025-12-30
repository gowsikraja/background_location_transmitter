package com.example.background_location_transmitter

/**
 * Holds runtime configuration for location transmission.
 *
 * This object stores API configuration provided by Flutter
 * and is accessed by [LocationService] while tracking is active.
 *
 * The configuration is kept in memory only and cleared
 * automatically when tracking stops.
 */
object TrackingConfig {

    /** Backend API endpoint URL */
    var apiUrl: String? = null

    /** HTTP headers to include with each request */
    var headers: Map<String, String>? = null

    /** Base payload shared across all location updates */
    var baseBody: Map<String, Any>? = null

    /** Enable/disable debug logging */
    var debug: Boolean = true

    /** Location update interval in milliseconds */
    var interval: Long = 10000

    /**
     * Returns `true` if all required configuration fields
     * are available and valid.
     */
    fun isValid(): Boolean {
        return apiUrl != null && headers != null && baseBody != null
    }

    /**
     * Clears all stored configuration.
     *
     * This is invoked when tracking stops or the service
     * is destroyed to avoid leaking stale data.
     */
    fun clear() {
        apiUrl = null
        headers = null
        baseBody = null
        debug = true
        interval = 10000
    }
}
