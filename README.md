## background_location_transmitter

A production-grade Flutter plugin for **background location tracking and server-side transmission** using native Android foreground services.

This plugin is designed for applications that need to:
- Track location reliably in the background
- Continue tracking even when the app is closed or killed
- Transmit location data to a backend API
- Receive live location updates in Flutter when the app is active

> ⚠️ **Android only (for now)**  
> iOS support is planned for a future release.

---

### 🔍 Why Native Background Services (and not Flutter Headless)
Background location tracking is a platform-level responsibility, and relying solely on Flutter (including headless execution) is not reliable for production use cases.

####  ❌ Limitations of Pure Flutter / Headless Approaches
A pure Flutter implementation (including headless isolates) cannot reliably track location when the app is killed due to platform constraints:

Android
- OEM battery optimizations aggressively stop Dart isolates
- Headless Flutter execution is not guaranteed after app kill
- Background execution may stop without warning on many devices

iOS
- Strict background execution limits enforced by the OS
- Headless Flutter execution is not supported for continuous location
- Background tasks are heavily restricted and time-limited

Even well-known Flutter plugins may stop working once the app is force-killed by the user or the system.

## ✅ Why This Plugin Uses Native Implementation
This plugin intentionally delegates background location tracking to native platform services:

### ✨ Features

- ✅ Native Android foreground service
- ✅ Background location tracking (app closed / killed)
- ✅ Server-side transmission with configurable API
- ✅ Live location stream to Flutter
- ✅ One-time current location fetch
- ✅ Android 14+ compliant
- ❌ No UI or permission dialogs (handled by the app)

---

## 📦 Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  background_location_transmitter: <latest_version>
```

## 🚀 Usage

### 1️⃣ Configure & Start Tracking
Call `startTracking` with your API configuration. You can specify the HTTP method, headers, and body.

```dart
import 'package:background_location_transmitter/background_location_transmitter.dart';

await BackgroundLocationTransmitter.instance.startTracking(
  LocationApiConfig(
    url: 'https://api.example.com/v1/update_location',
    method: HttpMethod.post, // Supported: POST, PUT, PATCH
    headers: {
      'Authorization': 'Bearer YOUR_TOKEN',
      'Content-Type': 'application/json',
    },
    body: {
      'user_id': 'user_123',
      'device_id': 'android_x',
      // Location fields are auto-appended if no placeholders are used
    },
  ),
  trackingConfig: const TrackingConfig(
    debug: true, // Enable debug logs
    locationUpdateInterval: Duration(seconds: 10),
  ),
);
```

### ⚡ Dynamic Requests & Customization
The plugin supports **dynamic placeholders** for granular control over your API request format. You can use these placeholders in both the **URL** and the **Body**.

**Supported Placeholders:**
- `%latitude%`
- `%longitude%`
- `%speed%`
- `%accuracy%`
- `%timestamp%`

#### Scenario A: Custom Body Structure
Use placeholders to define your own JSON schema. If placeholders are detected in the body, the plugin **disables auto-appending** and sends exactly what you define.

```dart
LocationApiConfig(
  url: 'https://api.example.com/driver/location',
  method: HttpMethod.put,
  body: {
    'driverId': 'D-101',
    'coordinates': {
      'lat': '%latitude%',
      'lng': '%longitude%'
    },
    'meta': {
      'speed_mps': '%speed%',
      'accuracy_m': '%accuracy%'
    }
  },
);
// Result Payload: {"driverId": "...", "coordinates": {"lat": "...", "lng": "..."}, ...}
```

#### Scenario B: Query Parameters Only (No Body)
If you prefer sending data via URL parameters, use placeholders in the URL and **omit the body**.

```dart
LocationApiConfig(
  url: 'https://api.example.com/update?lat=%latitude%&lng=%longitude%',
  method: HttpMethod.put,
  // body is null/omitted
);
// Result Request: PUT https://api.example.com/update?lat=12.34&lng=56.78
// Body: {}
```

## ⚙️ Android Setup
### 1️⃣ Permissions
Add the following permissions to your app’s AndroidManifest.xml:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

ℹ️ This plugin does not request permissions automatically.
The host application must request and manage permissions before starting tracking.

### 🔐 Permissions (Important)
The plugin assumes permissions are already granted.

Recommended approach in Flutter:

- Use `permission_handler` 
- Request locationAlways permission
- Start tracking only after permission is granted

---

## ⚠️ Limitations

- ❌ Cannot survive force-stop by the user
- ❌ Background execution depends on OEM battery policies
- ❌ Android only (iOS planned)

These are Android platform limitations, not plugin bugs.

---

## 🗺️ Roadmap
- iOS support
- Offline queue & retry
- Encrypted payload support
- Custom transmission strategies
- Federated plugin architecture

---

## 🧑‍💻 Maintainers
Built with ❤️ for production use.

Contributions, issues, and PRs are welcome.
