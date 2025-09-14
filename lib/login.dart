import 'package:app_6/shopper_signup.dart';
import 'package:flutter/material.dart';
import 'user_home.dart';  // Import UserHome screen
import 'shopper_home.dart';  // Import ShopperHome screen
import 'api_service.dart';  // Import your API service here
import 'user_signup.dart';
import 'bottom_navbar.dart';
import 'bot_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = false;
  String? emailError;
  String? passwordError;
  String? loginError;

  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return emailRegExp.hasMatch(email);
  }

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    setState(() {
      emailError = email.isEmpty ? "Email cannot be empty!" : (!_isValidEmail(email) ? "Enter a valid email address" : null);
      passwordError = password.isEmpty ? "Password cannot be empty!" : null;
      loginError = null; // Clear previous login error
    });

    if (emailError != null || passwordError != null) {
      return; // Stop if validation fails
    }

    setState(() {
      isLoading = true;
    });

    final response = await ApiService.login(email, password);

    setState(() {
      isLoading = false;
    });

    print('Login Response: $response');

    if (response.containsKey('id')) {
      String role = response['role']; // Get role from the response

      // Save login state
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('role', role);
      await prefs.setString('userData', jsonEncode(response)); // Save full user data

      // Navigate to the appropriate screen
      Widget nextScreen;
      if (role == 'user') {
        nextScreen = NavigationMenu(responseData: response);
      } else {
        nextScreen = ShopperNavigation(responseData: response);
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
            (route) => false,
      );
    } else {
      setState(() {
        loginError = response['message'] ?? "Invalid credentials. Try again!";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              'assets/welcome.gif',
              height: 350,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 0),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                      errorText: emailError, // Shows error below email field
                    ),
                    onChanged: (value) {
                      setState(() {
                        emailError = null;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      errorText: passwordError, // Shows error below password field
                    ),
                    onChanged: (value) {
                      setState(() {
                        passwordError = null;
                      });
                    },
                  ),
                  SizedBox(height: 30),
                  // Shows login error (e.g., incorrect credentials) above Login button
                  if (loginError != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        loginError!,
                        style: TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
                  Text(
                    'Don\'t have an account? Sign up as',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to UserSignup screen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => UserSignup()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/user.png',
                              height: 60,
                              width: 60,
                            ),
                            SizedBox(width: 10),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'User',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 30),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to UserSignup screen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => ShopperSignup()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/hawker.png',
                              height: 60,
                              width: 50,
                            ),
                            SizedBox(width: 10),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Hawker',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ],
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
    );
  }
}