import 'package:http/http.dart' as http;
import 'dart:convert';
class ApiService {
  static const String _baseUrl = 'https://volarfashion.in/app/api.php';


  //LOGIN
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final Uri url = Uri.parse('$_baseUrl?email=$email&password=$password');

      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'}, // Ensure JSON format
      );

      print('Response Code: ${response.statusCode}');
      print('Raw Response Body: "${response.body}"');

      if (response.statusCode == 200) {
        try {
          // Trim any extra spaces in the response to avoid parsing issues
          final String trimmedResponse = response.body.trim();

          // Ensure it's valid JSON before decoding
          final Map<String, dynamic> jsonResponse = jsonDecode(trimmedResponse);

          print('Parsed JSON: $jsonResponse'); // Debugging Line
          return jsonResponse;
        } catch (e) {
          print('JSON Parse Error: $e'); // Debugging Line
          return {'status': 'error', 'message': 'Login Failed'};
        }
      } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Login Failed: $e'};
    }
    }
}