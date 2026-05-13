import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';
  
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth Methods
  static Future<Map<String, dynamic>> login(String phone, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phoneNumber': phone, 'password': password}),
    );
    
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', data['accessToken']);
      await prefs.setString('userId', data['userId']);
      return data;
    } else {
      throw Exception('Login failed: ${res.body}');
    }
  }

  static Future<Map<String, dynamic>> register(String firstName, String lastName, String phone, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phone,
        'password': password,
      }),
    );
    
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', data['accessToken']);
      await prefs.setString('userId', data['userId']);
      return data;
    } else {
      throw Exception('Registration failed: ${res.body}');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('userId');
  }

  // GET Request helper
  static Future<dynamic> get(String endpoint) async {
    final res = await http.get(Uri.parse('$baseUrl$endpoint'), headers: await _getHeaders());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    } else {
      throw Exception('GET request failed: ${res.statusCode} ${res.body}');
    }
  }

  // POST Request helper
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    } else {
      throw Exception('POST request failed: ${res.statusCode} ${res.body}');
    }
  }

  // PUT Request helper
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    } else {
      throw Exception('PUT request failed: ${res.statusCode} ${res.body}');
    }
  }

  // DELETE Request helper
  static Future<dynamic> delete(String endpoint) async {
    final res = await http.delete(Uri.parse('$baseUrl$endpoint'), headers: await _getHeaders());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    } else {
      throw Exception('DELETE request failed: ${res.statusCode} ${res.body}');
    }
  }
}
