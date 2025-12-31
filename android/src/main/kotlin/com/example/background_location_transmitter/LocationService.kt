package com.example.background_location_transmitter

import android.Manifest
import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.os.Build
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.pm.PackageManager
import android.os.Looper
import androidx.annotation.RequiresPermission
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat

import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority

import io.flutter.plugin.common.EventChannel

import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.util.concurrent.Executors
import java.io.BufferedReader
import java.io.InputStreamReader


/**
 * Foreground service responsible for background location tracking.
 *
 * This service:
 * - Runs independently of the Flutter engine
 * - Continues tracking even when the app is closed or killed
 * - Uploads location data to a configured backend API
 * - Emits live location updates to Flutter when available
 *
 * The service lifecycle is explicitly controlled via
 * start/stop commands from Flutter.
 */

private const val CHANNEL_ID = "blt_location_channel"
private const val NOTIFICATION_ID = 1001

class LocationService : Service() {

    companion object {
        /**
         * Event sink used to deliver location updates to Flutter.
         *
         * This reference may be null when the Flutter engine
         * is not active and must always be accessed defensively.
         */
        var eventSink: EventChannel.EventSink? = null

        /**
         * Indicates whether the service is currently running.
         */
        var isServiceRunning: Boolean = false
    }

    private var fusedClient: FusedLocationProviderClient? = null
    private var locationCallback: LocationCallback? = null


    override fun onCreate() {
        super.onCreate()
        isServiceRunning = true
        fusedClient = LocationServices.getFusedLocationProviderClient(this)

        createNotificationChannel()

        startForeground(
            NOTIFICATION_ID,
            createNotification()
        )
        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED || ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        startLocationUpdates()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Ensure the service is restarted if terminated by the system
        return START_STICKY
    }

    // Executor for network operations to avoid blocking the main thread
    private val executor = Executors.newSingleThreadExecutor()

    override fun onDestroy() {
        // Stop receiving location updates and clear configuration
        fusedClient?.let { client ->
            locationCallback?.let { callback ->
                client.removeLocationUpdates(callback)
            }
        }
        executor.shutdown()
        ServiceState.saveRunning(this, true) 
        // if I destroy it intentionally (via stopTracking), I should save FALSE.
        // LocationService.onDestroy() is called when stopService() is called OR when system kills it.
        // If stopService() is called, we usually manually set sharedPrefs = false in the Plugin code (stopTracking).
        // If system kills it, onDestroy might be called.
        // The original code had `ServiceState.saveRunning(this, true)`. This looks weird. Why true in onDestroy?
        // Ah, maybe assuming if destroyed unexpectedly, we still want it "running" (true) so it restarts?
        // But `stopTracking` in Plugin calls `ServiceState.saveRunning(context, false)`.
        
        // Let's stick to just updating the static flag here.
        isServiceRunning = false
        TrackingConfig.clear()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /**
     * Starts continuous location updates using high accuracy.
     *
     * Each location update is:
     * - Transmitted to the backend API (if configured)
     * - Forwarded to Flutter listeners (if active)
     */
    @RequiresPermission(allOf = [Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION])
    private fun startLocationUpdates() {
        val interval = TrackingConfig.interval
        PluginLogger.logService("Configuring location request with interval: ${interval}ms")

        val request = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            interval
        )
            .setMinUpdateIntervalMillis(interval)
            .build()

        if (
            ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            PluginLogger.logError("Missing FINE_LOCATION permission. Stopping service.")
            stopSelf()
            return
        }

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                val location = result.lastLocation ?: return
                PluginLogger.logLocation("New location received: ${location.latitude}, ${location.longitude} (Accuracy: ${location.accuracy}m)")

                val data = mapOf(
                    "latitude" to location.latitude,
                    "longitude" to location.longitude,
                    "speed" to location.speed,
                    "accuracy" to location.accuracy,
                    "timestamp" to System.currentTimeMillis()
                )

                // Transmit to Flutter
                if (eventSink != null) {
                    PluginLogger.logAction("Publishing location to Flutter stream")
                    eventSink?.success(data)
                }

                // Transmit to Backend API if configured
                if (TrackingConfig.isValid()) {
                    transmitLocation(data)
                } else {
                    PluginLogger.logError("Cannot transmit location: Invalid configuration")
                }
            }
        }

        PluginLogger.logService("Requesting location updates from FusedLocationProvider")
        fusedClient?.requestLocationUpdates(
            request,
            locationCallback!!,
            Looper.getMainLooper()
        )
    }

    private fun replacePlaceholders(template: String, data: Map<String, Any>): String {
        if (data.isEmpty()) return template

        val regex = Regex("%(${data.keys.joinToString("|")})%")
        return regex.replace(template) { matchResult ->
            val key = matchResult.groupValues[1]
            data[key]?.toString() ?: matchResult.value
        }
    }

    private fun hasPlaceholdersRecursive(data: Any?, locationKeys: Set<String>): Boolean {
        return when (data) {
            is String -> locationKeys.any { data.contains("%$it%") }
            is Map<*, *> -> data.values.any { hasPlaceholdersRecursive(it, locationKeys) }
            is List<*> -> data.any { hasPlaceholdersRecursive(it, locationKeys) }
            else -> false
        }
    }

    private fun replacePlaceholdersRecursive(data: Any?, locationData: Map<String, Any>): Any? {
        return when (data) {
            is String -> replacePlaceholders(data, locationData)
            is Map<*, *> -> data.mapKeys { it.key.toString() }.mapValues { replacePlaceholdersRecursive(it.value, locationData) }
            is List<*> -> data.map { replacePlaceholdersRecursive(it, locationData) }
            else -> data
        }
    }

    private fun processBody(baseBody: Map<String, Any>?, locationData: Map<String, Any>, urlHasPlaceholders: Boolean): Map<String, Any> {
        if (baseBody == null) {
            // If URL has placeholders, data is sent via query params; return an empty body.
            // Otherwise, in legacy mode, use the location data as the body.
            return if (urlHasPlaceholders) emptyMap() else locationData
        }

        if (hasPlaceholdersRecursive(baseBody, locationData.keys)) {
            // Dynamic Mode: Recursively replace placeholders.
            @Suppress("UNCHECKED_CAST")
            return (replacePlaceholdersRecursive(baseBody, locationData) as? Map<String, Any>) ?: emptyMap()
        } else {
            // Legacy Mode: Append generic location fields.
            return mutableMapOf<String, Any>().apply {
                putAll(baseBody)
                putAll(locationData)
            }
        }
    }

    private fun transmitLocation(locationData: Map<String, Any>) {
        executor.submit {
            try {
                val rawUrl = TrackingConfig.apiUrl ?: return@submit
                val method = TrackingConfig.httpMethod
                
                // Process URL
                val urlString = replacePlaceholders(rawUrl, locationData)
                val urlHasPlaceholders = (rawUrl != urlString)
                
                val url = URL(urlString)
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = method
                connection.doOutput = true
                connection.connectTimeout = 10000
                connection.readTimeout = 10000

                // Add Headers
                val headers = TrackingConfig.headers
                headers?.forEach { (key, value) ->
                    connection.setRequestProperty(key, value)
                }
                connection.setRequestProperty("Content-Type", "application/json")

                // Process Body
                val finalBodyMap = processBody(TrackingConfig.baseBody, locationData, urlHasPlaceholders)
                val jsonBody = JSONObject(finalBodyMap).toString()

                // Log Request Details
                PluginLogger.logAction(
                    """
                    ⚡ Transmitting Location Request:
                    URL: $urlString
                    Method: $method
                    Headers: $headers
                    Body: $jsonBody
                    """.trimIndent()
                )

                // Write body
                OutputStreamWriter(connection.outputStream).use { writer ->
                    writer.write(jsonBody)
                    writer.flush()
                }

                val responseCode = connection.responseCode
                val responseBody = try {
                    val stream = if (responseCode in 200..299) connection.inputStream else connection.errorStream
                    stream?.bufferedReader()?.use { it.readText() } ?: ""
                } catch (e: Exception) {
                    "Unable to read response body: ${e.message}"
                }

                if (responseCode in 200..299) {
                    PluginLogger.logAction(
                        """
                        ✅ Server Response:
                        Code: $responseCode
                        Body: $responseBody
                        """.trimIndent()
                    )
                } else {
                    PluginLogger.logError(
                        """
                        ⚠️ Server Error:
                        Code: $responseCode
                        Body: $responseBody
                        """.trimIndent()
                    )
                }
                
                connection.disconnect()

            } catch (e: Exception) {
                PluginLogger.logError("❌ Transmission failed", e)
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Background Location Tracking",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Location Tracking Active")
            .setContentText("Tracking location in background")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .build()
    }
}
