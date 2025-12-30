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
    }

    private var fusedClient: FusedLocationProviderClient? = null
    private var locationCallback: LocationCallback? = null


    override fun onCreate() {
        super.onCreate()
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

    private fun transmitLocation(locationData: Map<String, Any>) {
        executor.submit {
            try {
                val urlString = TrackingConfig.apiUrl ?: return@submit
                val method = TrackingConfig.httpMethod
                
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

                // Construct Body
                val finalBodyMap = TrackingConfig.baseBody?.toMutableMap() ?: mutableMapOf()
                finalBodyMap.putAll(locationData)
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
