import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  // На реальном телефоне, где Termux крутит бэкенд — localhost работает.
  // Если API на другом устройстве — поменяй на IP (например 192.168.1.5).
  static const String baseUrl = 'http://localhost:8080';
  static String? _token;

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String role,
    required String firstName,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'phone': phone,
        'password': password,
        'role': role,
        'first_name': firstName,
      }),
    );
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> createOrder({
    required String description,
    required String address,
    double lat = 55.75,
    double lon = 37.62,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/orders'),
      headers: _headers,
      body: jsonEncode({
        'description': description,
        'address': address,
        'lat': lat,
        'lon': lon,
      }),
    );
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> nearbyOrders({
    double lat = 55.75,
    double lon = 37.62,
    int radius = 1000,
  }) async {
    final r = await http.get(
      Uri.parse('$baseUrl/api/orders/nearby?lat=$lat&lon=$lon&radius=$radius'),
      headers: _headers,
    );
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> acceptOrder(int id) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/orders/$id/accept'),
      headers: _headers,
    );
    return jsonDecode(r.body);
  }
}
