import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Клиент к бэкенду «Моё дело».
/// Все методы возвращают {ok: bool, data: {...}} или {ok: false, error: '...'}.
class Api {
  /// 127.0.0.1 работает, если бэкенд запущен на том же устройстве (Termux).
  /// Если API на другом устройстве — замени на IP (например 192.168.1.5).
  static const String baseUrl = 'http://127.0.0.1:8080';
  static const Duration _timeout = Duration(seconds: 8);

  static String? _token;

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    return _token;
  }

  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // -------- AUTH --------
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

  // -------- ORDERS --------
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

  // -------- PRIVATE --------
  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl$path'),
                headers: _headers,
                body: jsonEncode(body))
          .timeout(_timeout);
      return _handle(res);
    } on TimeoutException {
      return {'ok': false, 'error': 'Сервер долго не отвечает. Он точно запущен?'};
    } on SocketException catch (e) {
      return {'ok': false, 'error': 'Нет связи с сервером: ${e.osError?.message ?? e.message}'};
    } on FormatException {
      return {'ok': false, 'error': 'Сервер вернул некорректный ответ'};
    } catch (e) {
      return {'ok': false, 'error': 'Неизвестная ошибка: $e'};
    }
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl$path'), headers: _headers)
          .timeout(_timeout);
      return _handle(res);
    } on TimeoutException {
      return {'ok': false, 'error': 'Сервер долго не отвечает'};
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
