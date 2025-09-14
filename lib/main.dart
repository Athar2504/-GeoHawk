import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'shopper_notification.dart';
import 'login.dart';
import 'user_home.dart';
import 'shopper_home.dart';
import 'bottom_navbar.dart';
import 'bot_nav_bar.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget? initialScreen;

  @override
  void initState() {
    super.initState();
    _startLandingPage(); // Show landing page first
  }

  void _startLandingPage() {
    Future.delayed(Duration(seconds: 5), () {
      checkLoginStatus();
    });
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      String role = prefs.getString('role') ?? '';
      String? userData = prefs.getString('userData');

      if (userData != null && userData.isNotEmpty) {
        Map<String, dynamic> user = jsonDecode(userData);

        if (role == 'user') {
          setState(() {
            initialScreen = NavigationMenu(responseData: user);
          });
        } else if (role == 'shopper') {
          setState(() {
            initialScreen = ShopperNavigation(responseData: user);
          });
        } else {
          setState(() {
            initialScreen = LoginScreen();
          });
        }
      } else {
        setState(() {
          initialScreen = LoginScreen();
        });
      }
    } else {
      setState(() {
        initialScreen = LoginScreen();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: initialScreen ?? LandingPage(), // Show landing page initially
    );
  }
}

// 🟢 Landing Page Widget (Shows for 10 Seconds)
class LandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Customize color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/animate.gif"), // App logo
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

