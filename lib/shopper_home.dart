import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'shopper_mapview.dart';
import 'NotificationPanel.dart';

class Shopperhome extends StatefulWidget {
  final Map<String, dynamic> responseData;

  const Shopperhome({Key? key, required this.responseData}) : super(key: key);

  @override
  _ShopperHomeState createState() => _ShopperHomeState();
}

class _ShopperHomeState extends State<Shopperhome> {
  bool isOnline = false;
  bool isOffline = true; // Initially offline
  bool _isUpdatingStatus = false; // ✅ Added loading state
  String shopperLocation = "Fetching location...";
  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool hasNotifications = false;  // Track if there are notifications

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadShopperStatus();
    checkForNotifications();
  }

  void _initializeNotifications() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    _notificationsPlugin.initialize(initializationSettings);
  }

  // Simulate checking for notifications
  void checkForNotifications() {
    // You can modify this logic to check for real notifications from an API or local data
    setState(() {
      hasNotifications = true; // Change this based on real conditions
    });
  }

  Future<void> _showPersistentNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vendor_status_channel',
      'Vendor Status',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      'Hawker Online',
      'You are visible to your customers. Turn off to go offline.',
      notificationDetails,
    );
  }

  Future<void> _cancelNotification() async {
    await _notificationsPlugin.cancel(0);
  }

  void _updateLocation(String newLocation) {
    setState(() {
      shopperLocation = newLocation;
    });
  }


  Future<void> _loadShopperStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool storedStatus = prefs.getBool("isOnline") ?? false;

    if (!mounted) return; // ✅ Prevents setState if widget is gone

    setState(() {
      isOnline = storedStatus;
      isOffline = !storedStatus;
    });

    if (isOnline) {
      _showPersistentNotification();
    }

    await updateShopperStatus(isOnline ? 1 : 0);
  }

  Future<void> _saveShopperStatus(bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isOnline", status);
  }

  /// **Update Shopper Online Status on the Server**
  Future<void> updateShopperStatus(int flag) async {
    if (!mounted) return;
    setState(() => _isUpdatingStatus = true); // ✅ Show loading

    try {
      final email = widget.responseData['email'];
      final url = Uri.parse('https://volarfashion.in/app/flag.php?email=$email&flag=$flag');

      print("🔄 Sending request to: $url");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        print("✅ API Response: ${response.body}");
      } else {
        print("❌ Failed to update shopper flag: ${response.statusCode}");
      }
    } catch (e) {
      print("❗ Network error: $e");
    } finally {
      if (!mounted) return;
      setState(() => _isUpdatingStatus = false); // ✅ Hide loading
    }
  }

  /// **Toggle Online/Offline Status**
  void _toggleOnlineStatus() async {
    if (_isUpdatingStatus) return; // ✅ Prevent multiple rapid taps

    bool newStatus = !isOnline;
    bool newOfflineStatus = !newStatus; // Ensuring opposite state

    setState(() {
      isOnline = newStatus;
      isOffline = newOfflineStatus;
    });

    await _saveShopperStatus(isOnline);
    await updateShopperStatus(isOnline ? 1 : 0);

    if (isOnline) {
      _showPersistentNotification();
    } else {
      _cancelNotification();
    }
  }


  @override
  Widget build(BuildContext context) {
    String shopperName = widget.responseData['username'] ?? 'Shopper';

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            /// **Profile Image & Welcome Message**
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green.shade200,
                  child: const Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("WELCOME", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(shopperName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on, color: isOnline ? Colors.green : Colors.red),
                const SizedBox(width: 5),
                Expanded(child: Text(shopperLocation, style: const TextStyle(fontSize: 16))),
              ],
            ),

            const SizedBox(height: 15),

            /// **Map View (Rounded with Green Outline)**
            Container(
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15), // ✅ Rounded Corners
                border: Border.all(color: Colors.blueGrey, width: 4), // ✅ Green Outline
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)], // ✅ Soft Shadow
              ),
              clipBehavior: Clip.antiAlias, // ✅ Ensures child follows rounded corners
              child: ShopperMapView(
                isOnline: isOnline,
                onLocationUpdated: _updateLocation,
                responseData: widget.responseData,
              ),
            ),


            const SizedBox(height: 20),

            /// **Toggle Button for Online Status**
            Row(
              children: [
                const Text("  Start Vendoring :", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleOnlineStatus,
                  child: Container(
                    width: 200,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Stack(
                        children: [
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: isOnline ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              width: 100,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isOnline ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isOnline ? "ONLINE" : isOffline ? "OFFLINE" : "",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                        ]
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Text(
              " Note: You will be sharing live location until the toggle is off",
              style: TextStyle(color: Colors.red, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationPanelPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: Center(child: const Text("Notification details here...")),
    );
  }
}