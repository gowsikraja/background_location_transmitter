package com.example.background_location_transmitter

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import io.flutter.plugin.common.MethodChannel

/**
 * Utility functions related to one-time location retrieval.
 *
 * This helper is used by the plugin to fetch the current
 * device location without starting background tracking.
 */
object LocationUtils {

    /**
     * Fetches the current device location and returns it
     * through the provided [result].
     *
     * This method:
     * - Uses high-accuracy location
     * - Does not start background tracking
     * - Falls back to last known location if needed
     */
    fun getCurrentLocation(
        context: Context,
        result: MethodChannel.Result
    ) {

        if (
            ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            PluginLogger.logError("Cannot fetch location: Permission denied")
            result.error(
                "PERMISSION_DENIED",
                "Location permission not granted",
                null
            )
            return
        }

        val fusedClient =
            LocationServices.getFusedLocationProviderClient(context)

        PluginLogger.logAction("Fetching high-accuracy location...")
        fusedClient.getCurrentLocation(
            Priority.PRIORITY_HIGH_ACCURACY,
            null
        ).addOnSuccessListener { location ->

            if (location != null) {
                PluginLogger.logLocation("One-time location fetched: ${location.latitude}, ${location.longitude}")
                result.success(
                    mapOf(
                        "latitude" to location.latitude,
                        "longitude" to location.longitude,
                        "accuracy" to location.accuracy,
                        "speed" to location.speed,
                        "timestamp" to location.time
                    )
                )
            } else {
                // Fallback to last known location
                PluginLogger.log("High-accuracy location null. Trying last known location...")
                fusedClient.lastLocation.addOnSuccessListener { lastLocation ->
                    if (lastLocation != null) {
                        PluginLogger.logLocation("Last known location found: ${lastLocation.latitude}, ${lastLocation.longitude}")
                        result.success(
                            mapOf(
                                "latitude" to lastLocation.latitude,
                                "longitude" to lastLocation.longitude,
                                "accuracy" to lastLocation.accuracy,
                                "speed" to lastLocation.speed,
                                "timestamp" to lastLocation.time
                            )
                        )
                    } else {
                        PluginLogger.logError("Unable to retrieve any location.")
                        result.error(
                            "NO_LOCATION",
                            "Unable to retrieve current location",
                            null
                        )
                    }
                }
            }
        }.addOnFailureListener {
            PluginLogger.logError("Location fetch failed", it)
            result.error(
                "LOCATION_ERROR",
                it.message,
                null
            )
        }
    }
}
