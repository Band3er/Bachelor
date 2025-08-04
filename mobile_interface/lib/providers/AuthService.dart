import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String registerUrl =
      '';
  static const String loginUrl =
      '';

  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String espMac,
  }) async {
    final response = await http.post(
      Uri.parse(registerUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'esp_mac': espMac,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return {'success': true, 'id': data['id']};
    } else {
      return {'success': false, 'error': data['error']};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(loginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'id': data['id'], 'esp_mac': data['esp_mac']};
    } else {
      return {'success': false, 'error': data['error']};
    }
  }
}
