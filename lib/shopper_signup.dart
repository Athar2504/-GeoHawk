import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app_6/login.dart';

class ShopperSignup extends StatefulWidget {
  @override
  _ShopperSignupState createState() => _ShopperSignupState();
}

class _ShopperSignupState extends State<ShopperSignup> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final String _apiUrl = "https://volarfashion.in/app/register.php";
  int? _selectedCategory;

  final List<String> _categories = [
    'FOOD & BEVERAGES', 'CLOTHING', 'VEGETABLES', 'SHOES', 'ACCESSORIES',
    'ELECTRONICS & APPLIANCES', 'BEAUTY PRODUCTS', 'TOYS', 'GROCERY',
    'HOUSEHOLD', 'OTHERS'
  ];

  final Map<String, int> _categoryMap = {
    'FOOD & BEVERAGES': 1, 'CLOTHING': 2, 'VEGETABLES': 3, 'SHOES': 4,
    'ACCESSORIES': 5, 'ELECTRONICS & APPLIANCES': 6, 'BEAUTY PRODUCTS': 7,
    'TOYS': 8, 'GROCERY': 9, 'HOUSEHOLD': 10, 'OTHERS': 11,
  };

  Future<bool> _registerShopper(String username, String email, String password, int category, String role) async {
    try {
      String requestUrl = "$_apiUrl?username=$username&email=$email&password=$password&category=$category&role=$role";

      var response = await http.get(Uri.parse(requestUrl));
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse.containsKey('message') && jsonResponse['message'] == 'User added successfully') {
          return true;
        } else {
          print("Error in API Response: ${jsonResponse['message']}");
          return false;
        }
      } else {
        print("Server Error: Status Code ${response.statusCode}");
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
              onPressed: () => Navigator.of(context).pop(),
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

      if (_selectedCategory == null) {
        _showAlertDialog("Error", "Please select a category", Colors.red);
        return;
      }

      bool registrationSuccess = await _registerShopper(username, email, password, _selectedCategory!, "shopper");

      if (registrationSuccess) {
        _showAlertDialog("Signup Successful!", "Your account has been created.", Colors.green);
        // Delay navigation for 2 seconds to allow the user to see the message
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
        });
      } else {
        _showAlertDialog("Signup Failed!", "Email is already in use or there was an error.", Colors.red);
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
              children: [
                SizedBox(height: 120),
                Text('Create your account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                SizedBox(height: 50),
                _buildTextField(_usernameController, "Business Name", Icons.business),
                SizedBox(height: 15),
                _buildTextField(_emailController, "Email", Icons.email, keyboardType: TextInputType.emailAddress),
                SizedBox(height: 15),
                _buildTextField(_passwordController, "Password", Icons.lock, isPassword: true),
                SizedBox(height: 15),
                DropdownButtonFormField<int>(
                  value: _selectedCategory,
                  decoration: _buildInputDecoration("Category", Icons.category),
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  items: _categories.map<DropdownMenuItem<int>>((String category) {
                    return DropdownMenuItem<int>(
                      value: _categoryMap[category],
                      child: Text(category),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Category is required' : null,
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: Text('Register', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                SizedBox(height: 30),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      decoration: _buildInputDecoration(label, icon),
      keyboardType: keyboardType,
      obscureText: isPassword,
      validator: (value) => value == null || value.isEmpty ? '$label is required' : null,
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.black87),
      filled: true,
      fillColor: Color(0xFFFFE5E5), // Restored Textbox Color ✅
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.black, width: 1),
      ),
      prefixIcon: Icon(icon, color: Colors.black87),
    );
  }
}
