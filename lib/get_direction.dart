import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;

class DirectionsPage extends StatefulWidget {
  final double hawkerLatitude;
  final double hawkerLongitude;
  final String hawkerName;

  DirectionsPage({
    required this.hawkerLatitude,
    required this.hawkerLongitude,
    required this.hawkerName,
  });

  @override
  _DirectionsPageState createState() => _DirectionsPageState();
}

class _DirectionsPageState extends State<DirectionsPage> {
  LatLng? _currentLocation;
  List<String> _navigationSteps = [];
  List<LatLng> _routePoints = [];
  Timer? _locationTimer;
  bool _hasArrived = false;
  double _direction = 0; // Stores the current compass direction

  double? _distanceLeft;
  double? _eta;

  final String _graphhopperApiKey = "2d95319b-9ba4-4356-b661-b916ee5220ce"; // Replace with your key
  final String _tomTomApiKey = "cxnwcmugyMiMFYcwKMrERpisTMIYANvq";

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        setState(() {
          _direction = event.heading ?? 0;
        });
      }
    });
  }

  @override
  void dispose() {
    print("🚀 Disposing screen and stopping timer");
    _locationTimer?.cancel();
    _stopLocationUpdates();
    _locationTimer = null;
    super.dispose();
  }

  /// **Forcefully Stop Location Updates**
  void _stopLocationUpdates() {
    print("🛑 Stopping location updates...");
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _fetchNavigationSteps();
      _locationTimer = Timer.periodic(Duration(seconds: 10), (timer) {
        _updateNavigation();
      });
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  Future<void> _fetchNavigationSteps() async {
    if (_currentLocation == null) return;

    final String url = "https://graphhopper.com/api/1/route?key=$_graphhopperApiKey";
    var body = jsonEncode({
      "points": [
        [_currentLocation!.longitude, _currentLocation!.latitude],
        [widget.hawkerLongitude, widget.hawkerLatitude]
      ],
      "profile": "foot",
      "instructions": true,
      "points_encoded": false
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data.containsKey("paths") && data["paths"].isNotEmpty) {
          List<dynamic> instructions = data["paths"][0]["instructions"];
          List<dynamic> points = data["paths"][0]["points"]["coordinates"];
          double distanceMeters = data["paths"][0]["distance"]; // Distance in meters
          double durationSeconds = data["paths"][0]["time"] / 1000; // Time in seconds

          setState(() {
            _navigationSteps = instructions.map((step) => step["text"] as String).toList();
            _routePoints = points.map((p) => LatLng(p[1], p[0])).toList();
            _distanceLeft = distanceMeters;
            _eta = durationSeconds;
          });
        }
      } else {
        print("Error fetching navigation: ${response.body}");
      }
    } catch (e) {
      print("Failed to fetch navigation: $e");
    }
  }

  Future<void> _updateNavigation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        widget.hawkerLatitude,
        widget.hawkerLongitude,
      );

      if (distance <= 10) {
        setState(() => _hasArrived = true);
        _locationTimer?.cancel();
      } else {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _distanceLeft = distance;
          _eta = (distance / 1.4); // Approximate walking speed 1.4 m/s
        });
      }
    } catch (e) {
      print("Error updating navigation: $e");
    }
  }

  void _exitNavigation() {
    _locationTimer?.cancel();
    Navigator.pop(context);
  }

  /// ✅ Floating Box for ETA & Distance (With Exit Button)
  Widget _buildEtaDistanceBox(BuildContext context) {
    String distanceText = "--";
    if (_distanceLeft != null) {
      distanceText = _distanceLeft! >= 1000
          ? "${(_distanceLeft! / 1000).toStringAsFixed(2)} km"
          : "${_distanceLeft!.toStringAsFixed(0)} m";
    }

    String etaText = _eta != null ? "${(_eta! ~/ 60)} min" : "--";

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Time Left & Distance
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      etaText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.directions_walk, color: Colors.blue, size: 22),
                  ],
                ),
                Text(
                  distanceText,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),

            // Exit Button
            ElevatedButton(
              onPressed: () => _exitNavigation(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: CircleBorder(),
                padding: EdgeInsets.all(14),
              ),
              child: Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Directions to ${widget.hawkerName}")),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                center: _currentLocation ?? LatLng(widget.hawkerLatitude, widget.hawkerLongitude),
                zoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  "https://api.tomtom.com/map/1/tile/basic/main/{z}/{x}/{y}.png?key=$_tomTomApiKey",
                ),
                if (_currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation!,
                        width: 40.0,
                        height: 40.0,
                        child: Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                      ),
                      Marker(
                        point: LatLng(widget.hawkerLatitude, widget.hawkerLongitude),
                        width: 40.0,
                        height: 40.0,
                        child: Icon(Icons.store, color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4.0,
                        color: Colors.blue,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (_hasArrived)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  "You have arrived at ${widget.hawkerName}!\nEnjoy Shopping :)",
                  style: TextStyle(color: Colors.white, fontSize: 22),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Positioned(
            top: 20,
            left: 20,
            right: 70,
            child: Container(
              padding: EdgeInsets.all(12),
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: 200, // Maximum height limit
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // <-- Shrinks to fit small content
                children: [
                  Text("Navigation Steps:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 8),
                  Flexible( // <-- Prevents unnecessary expansion
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 150, // Allows space for steps without expanding too much
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _navigationSteps.map((step) => Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text("• $step", style: TextStyle(fontSize: 16)),
                          )).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 20,
            right: 10,
            child: Transform.rotate(
              angle: (_direction * (math.pi / 180) * -1), // Rotates based on heading
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.transparent, blurRadius: 5),
                  ],
                ),
                child: FittedBox( // Ensures icons scale properly
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.navigation, color: Colors.red, size: 100),   // Red North Arrow
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ✅ Bottom Positioned ETA & Distance Box
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildEtaDistanceBox(context),
          ),
        ],
      ),
    );
  }
}
