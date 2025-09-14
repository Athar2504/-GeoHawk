import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;

class ShopperMapView extends StatefulWidget {
  final bool isOnline;
  final Function(String) onLocationUpdated;
  final Map<String, dynamic> responseData;

  ShopperMapView({
    required this.isOnline,
    required this.onLocationUpdated,
    required this.responseData,
  });

  @override
  _ShopperMapViewState createState() => _ShopperMapViewState();
}

class _ShopperMapViewState extends State<ShopperMapView> {
  static const String _tomtomApiKey = "cxnwcmugyMiMFYcwKMrERpisTMIYANvq"; // Replace with actual key
  LatLng? _currentLocation;
  bool _isLoading = true;
  bool _showPin = true;
  Timer? _locationTimer, _blinkTimer;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startLocationRefresh();
    if (widget.isOnline) {
      _startBlinkingPin();
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _blinkTimer?.cancel();
    super.dispose();
  }

  /// **Fetch Current Location & Convert to Address**
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw "Location services are disabled.";

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw "Location permission denied.";
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng latLng = LatLng(position.latitude, position.longitude);
      print("📍 Current Location: ${position.latitude}, ${position.longitude}");
      String address = await _reverseGeocode(latLng);

      setState(() {
        _currentLocation = latLng;
        _isLoading = false;
      });

      widget.onLocationUpdated(address); // ✅ Now sends address instead of coordinates

      _updateShopperLocation(position.latitude, position.longitude); // ✅ Always update location
    } catch (e) {
      print("❌ Error getting location: $e");
      setState(() => _isLoading = false);
    }
  }

  /// **Start Location Refresh (Every 10 sec)**
  void _startLocationRefresh() {
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      print("🔄 Refreshing location...");
      _getCurrentLocation(); // ✅ Now updates location even if offline
    });
  }

  /// **Reverse Geocoding: Convert Lat/Lng to Address**
  Future<String> _reverseGeocode(LatLng location) async {
    final url = "https://api.tomtom.com/search/2/reverseGeocode/${location.latitude},${location.longitude}.json?key=$_tomtomApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["addresses"].isNotEmpty ? data["addresses"][0]["address"]["freeformAddress"] : "Unknown location";
      } else {
        return "Address not found.";
      }
    } catch (e) {
      return "Error fetching address.";
    }
  }

  /// **Move Map to Location**
  void _moveToLocation(LatLng location) {
    _mapController.move(location, 15.0);
  }


  /// **Start Blinking Pin Only When Online**
  void _startBlinkingPin() {
    _blinkTimer?.cancel(); // Cancel any previous timer to avoid multiple timers

    if (widget.isOnline) {
      _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (mounted) {
          setState(() {
            _showPin = !_showPin; // ✅ Toggle pin visibility
          });
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _showPin = true; // ✅ Keep pin solid when offline
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant ShopperMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOnline != widget.isOnline) {
      _startBlinkingPin(); // ✅ Restart blinking logic when online status changes
    }
  }

  /// **Update Shopper Location to API**
  Future<void> _updateShopperLocation(double latitude, double longitude) async {
    try {
      final Uri url = Uri.parse(
        'https://volarfashion.in/app/shopper_location.php?email=${widget.responseData['email']}&latitude=$latitude&longitude=$longitude',
      );
      print("📡 Sending location update to: $url");

      final response = await http.get(url);

      print("📡 Sending location update to: $url");

      if (response.statusCode == 200) {
        print("✅ Location updated successfully: $latitude, $longitude");
        print("🔹 API Response: ${response.body}");
      } else {
        print("❌ Failed to update location. Status: ${response.statusCode}");
        print("🔸 Response Body: ${response.body}");
      }
    } catch (e) {
      print("❌ Error updating location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// **Map View**
        Positioned.fill(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
            mapController: _mapController,
            options: MapOptions(center: _currentLocation ?? LatLng(0, 0), zoom: 14.0),
            children: [
              TileLayer(urlTemplate: "https://api.tomtom.com/map/1/tile/basic/main/{z}/{x}/{y}.png?key=$_tomtomApiKey"),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 80.0,
                    height: 80.0,
                    child: Column(
                      children: [
                        /// **Username (Static - No Blinking)**
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
                          ),
                          child: Text(
                            widget.responseData['username'] ?? 'Shopper', // ✅ Corrected
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),

                        ),
                        const SizedBox(height: 3), // ✅ Spacing between text and pin

                        /// **Location Pin (Blinks Only When Green)**
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: widget.isOnline ? (_showPin ? 1.0 : 0.0) : 1.0, // ✅ Blink when online
                          child: Icon(Icons.location_pin,
                              color: widget.isOnline ? const Color(0xFF0A680E) : Colors.red,
                              size: 40),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        /// **Current Location Button**
        Positioned(
          bottom: 10,
          right: 10,
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () => _moveToLocation(_currentLocation!), // ✅ Move to Current Location
            child: const Icon(Icons.my_location, color: Colors.blue), // ✅ Blue Icon
          ),
        ),
      ],
    );
  }
}
