import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'user_mapview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'PaymentPage.dart';
import 'get_direction.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserHome extends StatefulWidget {
  final Map<String, dynamic> responseData;

  const UserHome({Key? key, required this.responseData}) : super(key: key);

  @override
  _UserHomeState createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  String? currentAddress;
  Position? _currentPosition;
  List<Map<String, dynamic>> _shoppers = [];
  final Map<String, List<String>> _imageResultCache = {};

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  /// **Get User Location**
  Future<void> _determinePosition() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
    _fetchShoppers(); // Fetch shoppers after getting location
  }

  /// **Haversine Formula for Distance Calculation**
  double _calculateDistance(double lat1, double lon1, double lat2,
      double lon2) {
    const double R = 6371000; // Earth's radius in meters
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
            sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in meters
  }

  /// **Fetch Shoppers & Sort by Distance**
  Future<void> _fetchShoppers() async {
    try {
      final Uri url = Uri.parse(
          'https://volarfashion.in/app/all_location.php?timestamp=${DateTime
              .now()
              .millisecondsSinceEpoch}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> fetchedShoppers = data.map((shopper) {
          double? lat = double.tryParse(shopper["latitude"].toString());
          double? lng = double.tryParse(shopper["longitude"].toString());
          if (lat == null || lng == null || shopper["flag"] != "1") return null;

          double distance = _currentPosition != null
              ? _calculateDistance(
              _currentPosition!.latitude, _currentPosition!.longitude, lat, lng)
              : double.infinity;

          // ❌ Ignore shoppers beyond 3 km
          if (distance > 3000) return null;

          return {
            "username": shopper["username"] ?? "Unknown",
            "latitude": lat,
            "longitude": lng,
            "distance": distance,
            "description": shopper["description"] ?? "No description",
            "email": shopper["email"] ?? "No email",
            "category": shopper["category"] ?? "No category",
            "flag": shopper["flag"],
          };
        }).whereType<Map<String, dynamic>>().toList();

        fetchedShoppers.sort((a, b) => a["distance"].compareTo(b["distance"]));

        setState(() {
          _shoppers = fetchedShoppers;
        });
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  /// **Format Distance**
  String _formatDistance(double distance) {
    if (distance < 1000) {
      return "${distance.toStringAsFixed(0)} m"; // Show in meters
    } else {
      return "${(distance / 1000).toStringAsFixed(
          2)} km"; // Convert to kilometers
    }
  }

  /// **Update Address**
  void updateAddress(String address) {
    setState(() {
      currentAddress = address;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [

            /// **Header Section**
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.green.shade200,
                    child: const Icon(
                        Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${widget.responseData['username']}!',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.pink,
                                size: 18),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                currentAddress ?? "Fetching location...",
                                style: GoogleFonts.poppins(
                                    fontSize: 14, color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// **Map Section**
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15), // Rounded corners
                  border: Border.all(
                      color: Colors.green, width: 2), // Outline color & width
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    width: double.infinity,
                    height: 500,
                    child: UserMapView(onLocationUpdated: updateAddress),
                  ),
                ),
              ),
            ),

            /// **Shoppers List (Nearest First)**
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nearby Shoppers",
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _shoppers.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _shoppers.length,
                    itemBuilder: (context, index) {
                      var shopper = _shoppers[index];
                      return GestureDetector(
                        onTap: () => _showShopDetails(context, shopper),
                        child: Card(
                          shape: RoundedRectangleBorder(

                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Row(
                              children: [

                                FutureBuilder<List<String>>(
                                  future: _getCachedOrFetchImages(shopper['email']),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.grey,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      );
                                    }

                                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                                      return CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.purple.shade500,
                                        child: const Icon(Icons.storefront, color: Colors.white, size: 30),
                                      );
                                    }

                                    return CircleAvatar(
                                      radius: 28,
                                      backgroundImage: NetworkImage(snapshot.data!.first),
                                    );
                                  },
                                ),


                                const SizedBox(width: 15),

                                /// **Shopper Details**
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text(shopper["username"],
                                          style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600)),
                                      Text(
                                          "${_formatDistance(
                                              shopper["distance"])} away",
                                          style: GoogleFonts.poppins(
                                              fontSize: 14, color: Colors.green)
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<List<String>> _getCachedOrFetchImages(String email) async {
    if (_imageResultCache.containsKey(email)) {
      return _imageResultCache[email]!;
    } else {
      final images = await _fetchShopperImages(email);
      _imageResultCache[email] = images;
      return images;
    }
  }


/// **Fetch Shopper Images**
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


///show shop details
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
              child: SingleChildScrollView(
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

                        /// **Display fetched images in a PageView**
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
                      constraints: BoxConstraints(maxWidth: 350),
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
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentPage(
                                shopperEmail: shopper["email"],
                                shopperName: shopper["username"],
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        icon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/upi_logo.png',
                              height: 40,
                            ),
                            SizedBox(width: 8),
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

                    /// Get Direction Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          double hawkerLatitude = (shopper['latitude'] as num).toDouble();
                          double hawkerLongitude = (shopper['longitude'] as num).toDouble();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DirectionsPage(
                                hawkerLatitude: hawkerLatitude,
                                hawkerLongitude: hawkerLongitude,
                                hawkerName: shopper['username'],
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF094ECA),
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Get Direction",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.directions,
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