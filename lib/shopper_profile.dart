import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'ShopperTransactionHistory.dart';
import 'package:permission_handler/permission_handler.dart';

class ShopperProfile extends StatefulWidget {
  final Map<String, dynamic> responseData;

  const ShopperProfile({Key? key, required this.responseData}) : super(key: key);

  @override
  _ShopperProfileState createState() => _ShopperProfileState();
}

class _ShopperProfileState extends State<ShopperProfile> {
  String shopperName = '';
  String email = '';
  String? profileImagePath;
  String businessDescription = '';
  String _upiId = 'No UPI ID added'; // Default text if no UPI ID is set
  bool _isLoading = true; // Initially loading the data
  TextEditingController _upiController = TextEditingController();
  List<String?> businessImageUrls = List.generate(3, (index) => null); // Store image URLs
  final ImagePicker _picker = ImagePicker();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchUpiId();
    _loadBusinessDescription(); // 👈 Load description on startup
    _loadBusinessImages(); // 🔹 Load previously saved image URLs
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      shopperName = prefs.getString('username') ?? widget.responseData['username'] ?? 'Shopper';
      email = widget.responseData['email'] ?? 'example@email.com';
      profileImagePath = prefs.getString('profile_image'); // Load profile image
    });
  }

  Future<void> _updateUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String newUsername = _usernameController.text;
    String? email = widget.responseData['email']; // Fetch email from SharedPreferences

    if (email == null) {
      print("❌ Email not found. Cannot update username.");
      return;
    }

    setState(() {
      shopperName = newUsername;
    });

    await prefs.setString('username', newUsername);

    try {
      final response = await http.get(
        Uri.parse(
            "https://volarfashion.in/app/shopper_username_update.php?email=$email&username=$newUsername"),
      );

      if (response.statusCode == 200) {
        print("✅ Username updated successfully");
      } else {
        print("❌ Failed to update username: ${response.body}");
      }
    } catch (e) {
      print("❌ Error updating username: $e");
    }
  }


  Future<void> _updateBusinessDescription() async {
    setState(() {
      businessDescription = _descriptionController.text;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('business_description', businessDescription);

    String? email = widget.responseData['email'];
    if (email == null) {
      print("❌ Email not found. Cannot update business description.");
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('description')
          .doc(email)
          .set({'description': businessDescription});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Business description updated!"),
            backgroundColor: Colors.green,
          ),
        );
      }

      print("✅ Business description updated successfully in Firestore");
    } catch (e) {
      print("❌ Error updating business description in Firestore: $e");
    }
  }




  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        profileImagePath = pickedFile.path;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', pickedFile.path);

      String? email = widget.responseData['email']; // Fetch email
      if (email != null) {
        await _uploadProfileImage(File(pickedFile.path), email);
      } else {
        print("❌ Email not found. Cannot upload profile image.");
      }
    }
  }

  Future<void> _uploadProfileImage(File imageFile, String email) async {
    if (!await _isConnectedToInternet()) {
      print("❌ No Internet Connection. Upload failed.");
      return;
    }

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("https://volarfashion.in/app/profile_image_update.php"), // ✅ Separate API
      );

      request.fields['email'] = email;
      request.files.add(await http.MultipartFile.fromPath("profile_image", imageFile.path));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print("✅ Profile image uploaded successfully");
      } else {
        print("❌ Failed to upload profile image. Response: $responseBody");
      }
    } catch (e) {
      print("❌ Error uploading profile image: $e");
    }
  }


  Future<void> _saveImageUrlToFirestore(int index, String imageUrl) async {
    try {
      DocumentReference userDoc = FirebaseFirestore.instance
          .collection("users")
          .doc(widget.responseData['email']);

      await userDoc.set({
        "business_images": List.generate(
          3,
              (i) => i == index ? imageUrl : (businessImageUrls[i] ?? ""),
        ),
      }, SetOptions(merge: true));

      print("✅ Image URL saved to Firestore at index $index");

      // 🔹 Show success SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Image uploaded successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("❌ Error saving image URL to Firestore: $e");

      // 🔹 Show error SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to upload image."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


  // 🔹 Pick image and upload to Imgur
  Future<void> _pickBusinessImage(int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      String? imageUrl = await _uploadImageToImgur(imageFile);
      if (imageUrl != null) {
        await _saveImageUrlToFirestore(index, imageUrl);
        setState(() {
          businessImageUrls[index] = imageUrl; // Update UI
        });
      }
    }
  }

  // 🔹 Upload image to Imgur
  Future<String?> _uploadImageToImgur(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("https://api.imgur.com/3/image"),
      );

      request.headers["Authorization"] = "Client-ID b5cb72edf99d16d"; // Replace with your Imgur Client ID
      request.files.add(await http.MultipartFile.fromPath("image", imageFile.path));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseBody);

      if (jsonResponse["success"]) {
        return jsonResponse["data"]["link"]; // Return image URL
      } else {
        print("❌ Imgur upload failed: ${jsonResponse["data"]["error"]}");
        return null;
      }
    } catch (e) {
      print("❌ Error uploading to Imgur: $e");
      return null;
    }
  }

  Future<bool> _isConnectedToInternet() async {
    try {
      final response = await http.get(Uri.parse("https://www.google.com"));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void showSnackbar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();

                await prefs.clear(); // ✅ Clears all data, including login state
                await prefs.setBool('isLoggedIn', false); // ✅ Explicitly set to false

                // ✅ Navigate to the login page and clear navigation stack
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                        (route) => false, // Removes all previous screens
                  );
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Fetch the UPI ID from Firebase
  Future<void> _fetchUpiId() async {
    String email = widget.responseData['email']; // Get email passed from the previous page

    try {
      DocumentSnapshot snapshot =
      await FirebaseFirestore.instance.collection('hawkers').doc(email).get();

      if (snapshot.exists) {
        setState(() {
          _upiId = snapshot['upi_id'] ?? 'No UPI ID added'; // Fetch UPI ID or set default
          _isLoading = false; // Stop loading
        });
      } else {
        setState(() {
          _isLoading = false; // Stop loading if document doesn't exist
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Stop loading in case of error
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching data')));
    }
  }

  // Save or update the UPI ID in Firestore
  Future<void> _saveUpiId() async {
    String email = widget.responseData['email'];
    String newUpiId = _upiController.text;

    if (newUpiId.isEmpty || !newUpiId.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid UPI ID')),
      );
      return;
    }

    // Save to Firestore
    await FirebaseFirestore.instance.collection('hawkers').doc(email).set({
      'email': email,
      'upi_id': newUpiId,
    }, SetOptions(merge: true));

    setState(() {
      _upiId = newUpiId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('UPI ID saved successfully')),
    );
  }

  // Show input dialog to edit UPI ID
  void _showUpiInputDialog() {
    if (_upiId == 'No UPI ID added') {
      // Only show the input dialog if no UPI ID is added
      _upiController.text = ''; // Reset the controller text if no UPI ID is added
    } else {
      _upiController.text = _upiId ?? ''; // Load existing UPI ID for editing
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter UPI ID"),
          content: TextField(
            controller: _upiController,
            decoration: InputDecoration(
              labelText: "Enter UPI ID",
              hintText: "e.g. hawker@upi",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Save"),
              onPressed: () {
                _saveUpiId();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopper Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// **Profile Image and Username**
            Row(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: profileImagePath != null
                            ? FileImage(File(profileImagePath!))
                            : null,
                        child: profileImagePath == null
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                      const Icon(Icons.edit, color: Colors.blueGrey),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          shopperName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueGrey),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Edit Username"),
                                content: TextField(
                                  controller: _usernameController,
                                  decoration: const InputDecoration(hintText: "Enter new username"),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _updateUsername();
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Save"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// **Business Images**
            const Text("Business Images", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (index) {
                return GestureDetector(
                  onTap: () => _pickBusinessImage(index),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: businessImageUrls[index] != null
                        ? Image.network(businessImageUrls[index]!, fit: BoxFit.cover) // Load from Firestore
                        : const Icon(Icons.add, size: 40, color: Colors.grey),
                  ),
                );
              }),
            ),

            const SizedBox(height: 30),

            /// **Business Description**
            _buildSection("Add Business Description"),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter business description",
                    ),
                    onSubmitted: (value) => _updateBusinessDescription(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueGrey),
                  onPressed: _updateBusinessDescription,
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// **Payment Section**
            _buildSection("Payment"),
            _buildListTile("Payment Settings", Icons.payment, Colors.green, () {
              _showUpiInputDialog();
            }),

            // This is where we show the UPI ID or the default message
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: _upiId == 'No UPI ID added'
                    ? Text(
                  'No UPI ID added',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                )
                    : Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '     Saved UPI ID: ',
                        style: TextStyle(
                          color: Colors.black, // Label in black
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: _upiId,
                        style: TextStyle(
                          color: Colors.green, // UPI ID in green
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            _buildListTile("Your Payment History", Icons.history, Colors.green, () {    Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShopperTransactionHistory(shopperEmail: widget.responseData['email']),
              ),
            );}),

            const SizedBox(height: 20),

            /// **Other Information**
            _buildSection("Other Information"),
            _buildListTile("About Us", Icons.info, Colors.green, () {}),
            _buildListTile("Account Privacy", Icons.lock, Colors.green, () {}),

            const SizedBox(height: 20),
            /// **Logout Button**
            Center(
              child: SizedBox(
                width: double.infinity, // Makes the button take full width
                child: ElevatedButton(
                  onPressed: () => _logout(context), // ✅ Pass context to function
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16), // Increased button height
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // Adds slight rounded corners
                    ),
                  ),
                  child: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22, // Bigger text
                      fontWeight: FontWeight.bold, // Makes text bold
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }


  Future<void> _loadBusinessImages() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.responseData['email'])
          .get();

      if (userDoc.exists) {
        List<dynamic>? imagesFromFirestore = userDoc['business_images'];

        if (imagesFromFirestore != null && imagesFromFirestore.length == 3) {
          setState(() {
            for (int i = 0; i < 3; i++) {
              businessImageUrls[i] = imagesFromFirestore[i] as String?;
            }
          });
          print("✅ Business images loaded successfully.");
        }
      }
    } catch (e) {
      print("❌ Error loading business images: $e");
    }
  }


  Future<void> _loadBusinessDescription() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedDescription = prefs.getString('business_description');

    // Optional: If not found in prefs, try loading from Firestore
    if (savedDescription == null || savedDescription.isEmpty) {
      try {
        String? email = widget.responseData['email'];
        if (email != null) {
          DocumentSnapshot doc = await FirebaseFirestore.instance
              .collection('description')
              .doc(email)
              .get();

          if (doc.exists && doc['description'] != null) {
            savedDescription = doc['description'];
          }
        }
      } catch (e) {
        print("❌ Error fetching description from Firestore: $e");
      }
    }

    if (savedDescription != null && savedDescription.isNotEmpty) {
      setState(() {
        _descriptionController.text = savedDescription ?? '';
        businessDescription = savedDescription ?? '';
      });
    }
  }


  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildListTile(String title, IconData icon, Color iconColor, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}

