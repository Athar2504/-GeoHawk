import 'package:app_6/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For parsing JSON

class UserSignup extends StatefulWidget {
  @override
  _UserSignupState createState() => _UserSignupState();
}

class _UserSignupState extends State<UserSignup> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // API URL for registration (Replace with your actual URL)
  final String _apiUrl = "https://volarfashion.in/app/register.php";

  Future<bool> _registerUser(String username, String email, String password, String role) async {
    try {
      // Constructing the GET request URL with parameters
      String requestUrl = "$_apiUrl?username=$username&email=$email&password=$password&role=$role";

      var response = await http.get(Uri.parse(requestUrl));

      print("Response: ${response.body}"); // Debugging

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse.containsKey('message') && jsonResponse['message'] == 'User added successfully') {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      print("Exception: $e");
      return false;
    }
  }

  void _showAlertDialog(String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(color: color)),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _signup() async {
    if (_formKey.currentState?.validate() ?? false) {
      final username = _usernameController.text;
      final email = _emailController.text;
      final password = _passwordController.text;

      bool registrationSuccess = await _registerUser(username, email, password, "user");

      if (registrationSuccess) {
        _showAlertDialog("Signup Successful!", "Your account has been created.", Colors.green);
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
        });
      } else {
        _showAlertDialog("Signup Failed!", "Email is already in use.", Colors.red);
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 200),
                Text(
                  'Create your account',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                SizedBox(height: 50),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.black87),
                    filled: true,
                    fillColor: Color(0xFFFFE5E5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black, width: 1),
                    ),
                    prefixIcon: Icon(Icons.person, color: Colors.black87),
                  ),
                  style: TextStyle(color: Colors.black),
                  validator: (value) => value == null || value.isEmpty ? 'Username is required' : null,
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.black87),
                    filled: true,
                    fillColor: Color(0xFFFFE5E5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black, width: 1),
                    ),
                    prefixIcon: Icon(Icons.email, color: Colors.black87),
                  ),
                  style: TextStyle(color: Colors.black),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';
                    RegExp regExp = RegExp(pattern);
                    if (!regExp.hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.black87),
                    filled: true,
                    fillColor: Color(0xFFFFE5E5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black, width: 1),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Colors.black87),
                  ),
                  style: TextStyle(color: Colors.black),
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty ? 'Password is required' : null,
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: Colors.black87),
                    filled: true,
                    fillColor: Color(0xFFFFE5E5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black, width: 1),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Colors.black87),
                  ),
                  style: TextStyle(color: Colors.black),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text('Register', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                SizedBox(height: 40),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text('Already have an account? Login', style: TextStyle(color: Colors.black87)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}