import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';

class UserProfile extends StatefulWidget {
  final Map<String, dynamic> responseData;

  const UserProfile({Key? key, required this.responseData}) : super(key: key);

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  String username = '';
  String email = '';
  String imageUrl = '';
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    username = widget.responseData['username'];
    email = widget.responseData['email'] ?? 'No Email Provided';
    imageUrl = widget.responseData['profile_image'] ?? '';
  }

  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile(String email, String newUsername, File? imageFile) async {
    bool usernameUpdated = false;
    bool imageUploaded = false;

    try {
      // Step 1: Update Username via GET request
      final usernameResponse = await http.get(
        Uri.parse(
            "https://volarfashion.in/app/shopper_username_update.php?email=$email&username=$newUsername"),
      );

      if (usernameResponse.statusCode == 200) {
        var usernameJson = json.decode(usernameResponse.body);
        setState(() {
          username = usernameJson['username'];
        });
        usernameUpdated = true;
      } else {
        print("❌ Failed to update username: ${usernameResponse.body}");
      }
    } catch (e) {
      print("❌ Error updating username: $e");
    }

    // Step 2: Upload Profile Image via POST request
    if (imageFile != null) {
      try {
        var imageRequest = http.MultipartRequest(
          "POST",
          Uri.parse("https://yourapi.com/upload-profile-image"),
        );

        imageRequest.fields['email'] = email;
        imageRequest.files.add(await http.MultipartFile.fromPath("profile_image", imageFile.path));

        var imageResponse = await imageRequest.send();
        var imageResponseBody = await imageResponse.stream.bytesToString();

        if (imageResponse.statusCode == 200) {
          var imageJson = json.decode(imageResponseBody);
          setState(() {
            imageUrl = imageJson['profile_image'];
          });
          imageUploaded = true;
        } else {
          print("❌ Failed to upload profile image: $imageResponseBody");
        }
      } catch (e) {
        print("❌ Error uploading profile image: $e");
      }
    }

    // Show final success or failure message
    if (usernameUpdated && imageUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'))
      );
    } else if (usernameUpdated) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated, but image upload failed'))
      );
    } else if (imageUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image uploaded, but username update failed'))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile update failed'))
      );
    }
  }


  void _showEditProfileDialog() {
    TextEditingController usernameController = TextEditingController(text: username);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Your Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Update Username"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickProfileImage,
              icon: const Icon(Icons.image),
              label: const Text("Change Picture"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await _updateProfile(email, usernameController.text, _selectedImage);
              Navigator.pop(context);
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close the dialog
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty ? const Icon(Icons.person, size: 60) : null,
            ),
            const SizedBox(height: 10),
            Text(username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showEditProfileDialog,
              icon: const Icon(Icons.edit),
              label: const Text("Edit Your Profile"),
            ),
            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Payment Section", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Your Payment History"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Other Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("About Us"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text("Account Privacy"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _confirmLogout, // Call the logout confirmation function
                child: const Text("Logout", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
