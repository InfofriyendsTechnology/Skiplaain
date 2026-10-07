import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // For Android Emulator: use 10.0.2.2 instead of localhost
  // For iOS Simulator/Physical Device: use your machine's IP address (e.g., http://192.168.x.x:61026/api)
  static const String baseUrl = 'http://10.0.2.2:61026/api';
  
  final _storage = const FlutterSecureStorage();
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Token management
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // Get user phone from storage
  Future<String?> getUserPhone() async {
    return await _storage.read(key: 'user_phone');
  }

  // Save user phone
  Future<void> saveUserPhone(String phone) async {
    await _storage.write(key: 'user_phone', value: phone);
  }

  // GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // PATCH request
  Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      return {
        'success': false,
        'message': body['message'] ?? 'Request failed',
        'statusCode': response.statusCode,
      };
    }
  }
}
