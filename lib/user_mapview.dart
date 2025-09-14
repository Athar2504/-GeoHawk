import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'get_direction.dart';
import 'dart:async'; // ✅ Import Timer
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'PaymentPage.dart';
import 'package:flutter/foundation.dart'; // ✅ Import this for listEquals
import 'dart:math';

class UserMapView extends StatefulWidget {
  final Function(String) onLocationUpdated;

  const UserMapView({Key? key, required this.onLocationUpdated}) : super(key: key);

  @override
  _UserMapViewState createState() => _UserMapViewState();
}

class _UserMapViewState extends State<UserMapView> {
  static const String _tomtomApiKey = "cxnwcmugyMiMFYcwKMrERpisTMIYANvq"; // Replace with actual key
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  Timer? _locationTimer, _searchDebounce, _shopperRefreshTimer;
  double _direction = 0; // Stores the current compass direction

  String _address = "Fetching location...";
  LatLng? _currentLocation;
  bool _isLoading = true;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _shoppers = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchShoppers();
    _startLocationRefresh();
    _fetchShoppers(); // ✅ Initial fetch
    _startAutoRefresh(); // ✅ Start auto-refresh
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
    _locationTimer?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _shopperRefreshTimer?.cancel(); // ✅ Stop Timer when leaving the page
    super.dispose();
  }

  /// *Fetch current location & update UI*
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw "Location services are disabled.";

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw "Location permission denied.";
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng latLng = LatLng(position.latitude, position.longitude);
      String address = await _reverseGeocode(latLng);

      if (mounted) {
        setState(() {
          _address = address;
          _currentLocation = latLng;
          _isLoading = false;
        });
        widget.onLocationUpdated(address);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// *Reverse geocode (convert lat/lng to address)*
  Future<String> _reverseGeocode(LatLng location) async {
    final url = "https://api.tomtom.com/search/2/reverseGeocode/${location
        .latitude},${location.longitude}.json?key=$_tomtomApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data["addresses"].isNotEmpty
            ? data["addresses"][0]["address"]["freeformAddress"]
            : "Unknown location";
      } else {
        return "Location fetching failed.";
      }
    } catch (e) {
      return "Error fetching address.";
    }
  }

  /// **Haversine Formula for Distance Calculation**
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000; // Earth's radius in meters
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
            sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in meters
  }

  Future<void> _fetchShoppers() async {
    try {
      final Uri url = Uri.parse('https://volarfashion.in/app/all_location.php?timestamp=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);

          // 🔍 Print raw API response
          //print("📡 Raw API Response: $data");

          List<Map<String, dynamic>> fetchedShoppers = data.map((shopper) {
            double? latitude = double.tryParse(shopper["latitude"].toString());
            double? longitude = double.tryParse(shopper["longitude"].toString());
            String? flag = shopper["flag"]?.toString();

            // ✅ Skip invalid coordinates
            if (latitude == null || longitude == null ||
                latitude < -90 || latitude > 90 ||
                longitude < -180 || longitude > 180 || flag != "1") {
              //print("❌ Skipping invalid location: ${shopper["latitude"]}, ${shopper["longitude"]}");
              return null;
            }

            double distance = (_currentLocation != null)
                ? _calculateDistance(
                _currentLocation!.latitude, _currentLocation!.longitude, latitude, longitude)
                : double.infinity;

            return {
              "username": shopper["username"] ?? "Unknown",
              "description": shopper["description"] ?? "No description",
              "email": shopper["email"] ?? "No email",
              "latitude": latitude,
              "longitude": longitude,
              "category": shopper["category"] ?? "No category",
              "flag": shopper["flag"],
              "distance": distance,
            };
          }).whereType<Map<String, dynamic>>().toList();

          fetchedShoppers.sort((a, b) => a["distance"].compareTo(b["distance"]));

          // 🔍 Print filtered and parsed shopper list
          //print("✅ Parsed Shoppers Data: $fetchedShoppers");

          // ✅ Update only if data has changed
          if (!listEquals(_shoppers, fetchedShoppers)) {
            setState(() {
              _shoppers = fetchedShoppers;
            });

            print("✅ Updated shopper list: ${_shoppers.length} items");
          } else {
            print("ℹ️ No changes in API data.");
          }
        } catch (jsonError) {
          print("❌ JSON Parsing Error: $jsonError");
        }
      } else {
        print("❌ API Request Failed: Status ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching shoppers: $e");
    }
  }

  /// **Format Distance**
  String _formatDistance(double distance) {
    if (distance < 1000) {
      return "${distance.toStringAsFixed(0)} m"; // Show in meters
    } else {
      return "${(distance / 1000).toStringAsFixed(2)} km"; // Convert to kilometers
    }
  }

  /// 🚀 Auto-Refresh Function
  void _startAutoRefresh() {
    _shopperRefreshTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchShoppers();
    });
  }

  /// *Refresh user location every 10 seconds*
  void _startLocationRefresh() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _getCurrentLocation();
    });
  }

  /// *Search for locations using TomTom API*
  void _searchLocation(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      final url = "https://api.tomtom.com/search/2/search/$query.json?key=$_tomtomApiKey";
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data["results"] != null && data["results"].isNotEmpty) {
            List<Map<String, dynamic>> results = data["results"]
                .map<Map<String, dynamic>>((feature) =>
            {
              "name": feature["address"]["freeformAddress"],
              "latitude": feature["position"]["lat"],
              "longitude": feature["position"]["lon"]
            })
                .toList();

            if (mounted) {
              setState(() {
                _searchResults = results;
              });
            }
          } else {
            setState(() => _searchResults.clear());
          }
        }
      } catch (e) {
        setState(() => _searchResults.clear());
      }
    });
  }

  void _moveToLocation(LatLng location) {
    _mapController.move(location, 15.0);
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
            mapController: _mapController,
            options: MapOptions(
                center: _currentLocation ?? LatLng(0, 0), zoom: 14.0),
            children: [
              TileLayer(
                  urlTemplate: "https://api.tomtom.com/map/1/tile/basic/main/{z}/{x}/{y}.png?key=$_tomtomApiKey"),
              MarkerLayer(
                markers: [
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 40.0,
                      height: 40.0,
                      child: const Icon(
                          Icons.location_pin, color: Colors.red, size: 40),
                    ),

                  // Shopper Markers with Click & Labels
                  ..._shoppers.map(
                        (shopper) =>
                        Marker(
                          point: LatLng(
                              shopper["latitude"], shopper["longitude"]),
                          width: 100.0,
                          height: 60.0,
                          child: GestureDetector(
                            onTap: () => _showShopDetails(context, shopper),
                            // ✅ Pass context from the widget tree
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 5), // spacing between label and pin
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  width: 150, // limit width to prevent overflow
                                  child: Text(
                                    shopper["username"],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    softWrap: false,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const Icon(
                                  Icons.pin_drop_sharp,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                              ],
                            ),
                          ),
                        ),
                  ),

                ],
              ),
            ],
          ),
        ),

        /// *Search Bar Overlay*
        Positioned(
          top: 20,
          left: 10,
          right: 10,
          child: Column(
            children: [

              /// *Search Field*
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25.0),
                  // ✅ More Rounded Corners
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchLocation,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    // ✅ White Background
                    labelText: "Search Location",
                    hintText: "Enter address or place name",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        // ✅ Rounded Borders
                        borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults.clear();
                          _moveToLocation(
                              _currentLocation!); // ✅ Move to Current Location
                        });
                      },
                    )
                        : null,
                  ),
                ),
              ),

              /// *Dropdown for Search Results (White Background)*
              if (_searchResults.isNotEmpty)
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: Colors.white, // ✅ White Background for Dropdown
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4)
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return ListTile(
                        title: Text(result["name"] ?? "Unknown"),
                        onTap: () {
                          _searchController.text = result["name"];
                          _moveToLocation(LatLng(
                              result["latitude"], result["longitude"]));
                          setState(() => _searchResults.clear());
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        Positioned(
          bottom: 85,
          right: 23,
          child: Transform.rotate(
            angle: (_direction * (math.pi / 180) * -1),
            // Rotates based on heading
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
                    Icon(Icons.navigation, color: Colors.red, size: 100),
                    // Red North Arrow
                  ],
                ),
              ),
            ),
          ),
        ),

        /// *Current Location Button*
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            // ✅ White Background
            onPressed: () => _moveToLocation(_currentLocation!),
            // ✅ Move to Current Location
            child: const Icon(
                Icons.my_location, color: Colors.blue), // ✅ Blue Icon
          ),
        ),
      ],
    );
  }


  Future<List<String>> _fetchShopperImages(String email) async {
    print("Fetching images for email: $email");

    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(email) // 🔥 Directly fetch document by email
          .get();

      if (docSnapshot.exists) {
        var data = docSnapshot.data() as Map<String, dynamic>;

        print("Firestore data for $email: $data"); // ✅ LOG DATA

        if (data.containsKey('business_images') && data['business_images'] is List) {
          List<String> images = List<String>.from(data['business_images']);
          print("Fetched images: $images"); // ✅ LOG IMAGES LIST
          return images;
        } else {
          print("No images found for $email");
        }
      } else {
        print("No document found for email: $email");
      }
    } catch (e) {
      print("Error fetching images: $e");
    }

    return [];
  }


  /// **Fetch Shopper Description**
  Future<String> _fetchShopperDescription(String email) async {
    print("Fetching description for email: $email");

    try {
      DocumentSnapshot descDoc = await FirebaseFirestore.instance
          .collection('description')
          .doc(email)
          .get();

      if (descDoc.exists) {
        var descData = descDoc.data() as Map<String, dynamic>;
        print("Firestore description data for $email: $descData");

        if (descData.containsKey('description')) {
          return descData['description'];
        }
      } else {
        print("No description document found for email: $email");
      }
    } catch (e) {
      print("Error fetching description: $e");
    }

    return "No description available"; // Default if not found
  }


  void _showShopDetails(BuildContext context, Map<String, dynamic> shopper) {
    final PageController _pageController = PageController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.45,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView( // Fixes box size issue
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// *Top Row with Close Button*
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: 40), // To balance UI
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    SizedBox(height: 10),

                    /// **Load images dynamically using FutureBuilder**
                    FutureBuilder<List<String>>(
                      future: _fetchShopperImages(shopper['email']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                          return Container(
                            height: 300,
                            child: Image.asset(
                              "assets/no_image.png",
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                            ),
                          );
                        }

                        // **Display fetched images in a PageView**
                        List<String> images = snapshot.data!;
                        return Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              height: 300,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: images.length,
                                itemBuilder: (context, index) {
                                  String imageUrl = images[index];

                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: imageUrl.startsWith("http")
                                        ? Image.network(
                                      imageUrl,
                                      width: double.infinity,
                                      height: 300,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                            "assets/no_image.png",
                                            width: double.infinity,
                                            height: 300,
                                            fit: BoxFit.cover);
                                      },
                                    )
                                        : Image.asset(imageUrl,
                                        width: double.infinity,
                                        height: 300,
                                        fit: BoxFit.cover),
                                  );
                                },
                              ),
                            ),

                            /// *Dots Indicator Inside Image*
                            Positioned(
                              bottom: 10,
                              child: SmoothPageIndicator(
                                controller: _pageController,
                                count: images.length,
                                effect: ExpandingDotsEffect(
                                  dotHeight: 7,
                                  dotWidth: 7,
                                  activeDotColor: Colors.black87,
                                  dotColor: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    SizedBox(height: 12),

                    /// *Shop Name & Rating in a Wider Rounded Box*
                    Container(
                      width: double.infinity,
                      // Makes it take full width
                      constraints: BoxConstraints(maxWidth: 350),
                      // Limits maximum width for a balanced layout
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(15),
                      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// Shop Name & Distance
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                                    children: [
                                      TextSpan(text: shopper["username"] ?? "Shop Name"),
                                      TextSpan(
                                        text: " | ${_formatDistance(shopper["distance"])} away",
                                        style: TextStyle(color: Colors.green),
                                      ),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 8),

                          /// Shop Description
                          Text(
                            "Hawker Description:",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 5),
                          FutureBuilder<String>(
                            future: _fetchShopperDescription(shopper['email']),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Text(
                                  "Loading description...",
                                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                                );
                              }
                              if (snapshot.hasError || snapshot.data == null) {
                                return Text(
                                  "Error fetching description",
                                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                                );
                              }

                              return Text(
                                snapshot.data!,
                                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 15),

                    /// UPI Payment Button
                    SizedBox(
                      width: double.infinity, // Make it take full width
                      height: 45, // Adjust height
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Pass the shopper's email when the user clicks the "Pay via UPI" button
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentPage(shopperEmail: shopper["email"], shopperName: shopper["username"]),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // Rounded corners
                          ),
                          elevation: 5, // Shadow effect
                        ),
                        icon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/upi_logo.png', // UPI logo image
                              height: 40, // Adjust size as needed
                            ),
                            SizedBox(width: 8), // Space between icon and text
                          ],
                        ),
                        label: Text(
                          "Pay via UPI",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),


                    SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          double hawkerLatitude = (shopper['latitude'] as num).toDouble();
                          double hawkerLongitude = (shopper['longitude'] as num).toDouble();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DirectionsPage(
                                    hawkerLatitude: hawkerLatitude,
                                    hawkerLongitude: hawkerLongitude,
                                    hawkerName: shopper['username'],
                                  ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF094ECA),
                          padding: EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                12), // Rounded corners
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          // Keeps button size minimal
                          children: [
                            Text(
                              "Get Direction",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8), // Space between text and icon
                            Icon(
                              Icons.directions, // Direction icon
                              color: Colors.white,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
