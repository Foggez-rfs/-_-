import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Клиент к бэкенду «Моё дело».
class Api {
  static const String baseUrl = 'http://127.0.0.1:8080';
  static const Duration _timeout = Duration(seconds: 8);

  static String? _token;
  static String? _role;

  static Future<void> saveToken(String token, {String? role}) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    if (role != null) {
      _role = role;
      await prefs.setString('role', role);
    }
  }

  static Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    return _token;
  }

  static String? getRole() => _role;

  static Future<void> logout() async {
    _token = null;
    _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
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
    return _post('/auth/register', {
      'phone': phone,
      'password': password,
      'role': role,
      'first_name': firstName,
    });
  }

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    return _post('/auth/login', {'phone': phone, 'password': password});
  }

  static Future<Map<String, dynamic>> createOrder({
    required String description,
    required String address,
    double lat = 55.75,
    double lon = 37.62,
  }) async {
    return _post('/api/orders', {
      'description': description,
      'address': address,
      'lat': lat,
      'lon': lon,
    });
  }

  static Future<Map<String, dynamic>> nearbyOrders({
    double lat = 55.75,
    double lon = 37.62,
    int radius = 1000,
  }) async {
    return _get('/api/orders/nearby?lat=$lat&lon=$lon&radius=$radius');
  }

  static Future<Map<String, dynamic>> acceptOrder(int id) async {
    return _post('/api/orders/$id/accept', {});
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _handle(res);
    } on TimeoutException {
      return {'ok': false, 'error': 'Сервер не отвечает. Он запущен?'};
    } on SocketException catch (e) {
      return {'ok': false, 'error': 'Нет связи: ${e.osError?.message ?? e.message}'};
    } catch (e) {
      return {'ok': false, 'error': 'Ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl$path'), headers: _headers)
          .timeout(_timeout);
      return _handle(res);
    } on TimeoutException {
      return {'ok': false, 'error': 'Сервер не отвечает'};
    } on SocketException catch (e) {
      return {'ok': false, 'error': 'Нет связи: ${e.osError?.message ?? e.message}'};
    } catch (e) {
      return {'ok': false, 'error': 'Ошибка: $e'};
    }
  }

  static Map<String, dynamic> _handle(http.Response res) {
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'ok': true, 'data': body};
      }
      return {'ok': false, 'error': body['error']?.toString() ?? 'Ошибка ${res.statusCode}'};
    } catch (_) {
      return {'ok': false, 'error': 'Сервер вернул некорректный ответ'};
    }
  }
}
