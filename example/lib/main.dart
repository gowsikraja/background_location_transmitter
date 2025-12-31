import 'package:background_location_transmitter/background_location_transmitter.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

/// Simple single-page example demonstrating
/// background_location_transmitter usage.
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ExampleHomePage(),
    );
  }
}

/// Demonstrates:
/// - Permission handling
/// - GPS enabled check
/// - Start/stop background tracking
/// - Receiving live location updates
/// - Fetching current location
/// - Detecting service running state
class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  final _plugin = BackgroundLocationTransmitter.instance;

  LocationData? _latestLocation;
  bool _trackingRunning = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _restoreTrackingState();
  }

  /// Restores service state when app is reopened.
  Future<void> _restoreTrackingState() async {
    final running = await _plugin.isTrackingRunning();

    if (!mounted) return;

    setState(() {
      _trackingRunning = running;
    });

    if (running) {
      _listenToLocationStream();
    }
  }

  /// Starts listening to live location updates.
  void _listenToLocationStream() {
    _plugin.locationStream.listen((location) {
      setState(() {
        _latestLocation = location;
      });
    });
  }

  /// Handles starting background tracking.
  Future<void> _startTracking() async {
    setState(() => _loading = true);

    final permissionGranted = await _plugin.checkPermission();
    if (!permissionGranted) {
      _showMessage('Location permission not granted');
      setState(() => _loading = false);
      return;
    }

    final locationEnabled = await _plugin.isLocationEnabled();
    if (!locationEnabled) {
      _showMessage('Please enable location services');
      setState(() => _loading = false);
      return;
    }

    //Example for PUT API configuration
    // final putConfig = LocationApiConfig(
    //   url: 'https://example.com/api/location?lat=%latitude%&lng=%longitude%&speed=%speed%&accuracy=%accuracy%&ts=%timestamp%',
    //   method: HttpMethod.put,
    //   headers: {
    //     'Authorization': 'Bearer DEMO_TOKEN',
    //     'Content-Type': 'application/json',
    //   },);

    // Example API configuration
    final config = LocationApiConfig(
      url: 'https://example.com/api/location',
      headers: {
        'Authorization': 'Bearer DEMO_TOKEN',
        'Content-Type': 'application/json',
      },
      body: {
        'userId': 'demo_user',
        'sessionId': 'session_123',
        'latitude': '%latitude%',
        'longitude': '%longitude%',
        'metadata': {
          'speed': '%speed%',
          'accuracy': '%accuracy%',
          'timestamp': '%timestamp%'
        },
      },
      method: HttpMethod.post,
    );

    // Optional: Customize tracking behavior
    final trackingConfig = TrackingConfig(
      debug: true,
      locationUpdateInterval: const Duration(seconds: 10),
    );

    await _plugin.startTracking(config, trackingConfig: trackingConfig);
    _listenToLocationStream();

    setState(() {
      _trackingRunning = true;
      _loading = false;
    });
  }

  /// Stops background tracking.
  Future<void> _stopTracking() async {
    await _plugin.stopTracking();

    setState(() {
      _trackingRunning = false;
      _latestLocation = null;
    });
  }

  /// Fetches a one-time current location.
  Future<void> _getCurrentLocation() async {
    final location = await _plugin.getCurrentLocation();

    if (location == null) {
      _showMessage('Unable to fetch current location');
      return;
    }

    setState(() {
      _latestLocation = location;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Background Location Transmitter')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildControls(),
            const SizedBox(height: 16),
            _buildLocationView(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tracking Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              _trackingRunning ? 'RUNNING' : 'STOPPED',
              style: TextStyle(
                color: _trackingRunning ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _loading || _trackingRunning ? null : _startTracking,
          child: const Text('Start Background Tracking'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: !_trackingRunning ? null : _stopTracking,
          child: const Text('Stop Background Tracking'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _getCurrentLocation,
          child: const Text('Get Current Location'),
        ),
      ],
    );
  }

  Widget _buildLocationView() {
    if (_latestLocation == null) {
      return const Text('No location available', textAlign: TextAlign.center);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latitude: ${_latestLocation!.latitude}'),
            Text('Longitude: ${_latestLocation!.longitude}'),
            Text('Accuracy: ${_latestLocation!.accuracy} m'),
            Text('Speed: ${_latestLocation!.speed} m/s'),
            Text(
              'Timestamp: ${_latestLocation!.timestamp}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
