import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage.dart';

/// Результат вызова API
class ApiResult {
  final bool ok;
  final dynamic data;
  final String? error;
  ApiResult({required this.ok, this.data, this.error});
}

/// HTTP-клиент к бэкенду «Моё дело»
class Api {
  static String? _baseUrl;
  static String? _token;

  static Future<void> init() async {
    _baseUrl = await Storage.getBaseUrl();
    _token = await Storage.getToken();
  }

  static Future<void> setBaseUrl(String url) async {
    url = url.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    _baseUrl = url;
    await Storage.saveBaseUrl(url);
  }

  static String? get baseUrl => _baseUrl;
  static String? get token => _token;

  static Future<void> logout() async {
    _token = null;
    await Storage.clearToken();
  }

  static Map<String, String> get _h => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ---------- HTTP helpers ----------
  static Future<ApiResult> _post(String path, Map<String, dynamic> body) async {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      return ApiResult(ok: false, error: 'URL сервера не задан');
    }
    try {
      final r = await http
          .post(Uri.parse('$_baseUrl$path'),
              headers: _h, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return _handle(r);
    } on Exception catch (e) {
      return ApiResult(ok: false, error: 'Нет связи: $e');
    }
  }

  static Future<ApiResult> _get(String path) async {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      return ApiResult(ok: false, error: 'URL сервера не задан');
    }
    try {
      final r = await http
          .get(Uri.parse('$_baseUrl$path'), headers: _h)
          .timeout(const Duration(seconds: 15));
      return _handle(r);
    } on Exception catch (e) {
      return ApiResult(ok: false, error: 'Нет связи: $e');
    }
  }

  static ApiResult _handle(http.Response res) {
    try {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return ApiResult(ok: true, data: data);
      }
      final err =
          data is Map ? data['error']?.toString() : null;
      return ApiResult(ok: false, error: err ?? 'Ошибка ${res.statusCode}');
    } catch (_) {
      return ApiResult(ok: false, error: 'Сервер вернул некорректный ответ');
    }
  }

  // ---------- AUTH ----------
  static Future<ApiResult> register({
    required String phone,
    required String password,
    required String role,
    required String firstName,
  }) async {
    final r = await _post('/auth/register', {
      'phone': phone,
      'password': password,
      'role': role,
      'first_name': firstName,
    });
    if (r.ok) {
      _token = r.data['token'];
      await Storage.saveToken(r.data['token']);
      await Storage.saveRole(r.data['role'] ?? role);
      await Storage.saveName(r.data['name'] ?? firstName);
    }
    return r;
  }

  static Future<ApiResult> login({
    required String phone,
    required String password,
  }) async {
    final r = await _post('/auth/login', {
      'phone': phone,
      'password': password,
    });
    if (r.ok) {
      _token = r.data['token'];
      await Storage.saveToken(r.data['token']);
      await Storage.saveRole(r.data['role'] ?? 'customer');
      await Storage.saveName(r.data['name'] ?? '');
    }
    return r;
  }

  // ---------- ORDERS ----------
  static Future<ApiResult> createOrder({
    required String description,
    required String address,
    double lat = 55.75,
    double lon = 37.62,
  }) =>
      _post('/api/orders', {
        'description': description,
        'address': address,
        'lat': lat,
        'lon': lon,
      });

  static Future<ApiResult> nearbyOrders({
    double lat = 55.75,
    double lon = 37.62,
    int radius = 5000,
  }) =>
      _get('/api/orders/nearby?lat=$lat&lon=$lon&radius=$radius');

  /// Мои заказы — заказчик видит свои, исполнитель — принятые
  static Future<ApiResult> myOrders() => _get('/api/orders/my');

  static Future<ApiResult> acceptOrder(int id) =>
      _post('/api/orders/$id/accept', {});

  static Future<ApiResult> completeOrder(int id) =>
      _post('/api/orders/$id/complete', {});

  /// Оценка работы исполнителя заказчиком
  static Future<ApiResult> rateOrder({
    required int orderId,
    required int score,
    String comment = '',
  }) =>
      _post('/api/orders/$orderId/rate', {
        'score': score,
        'comment': comment,
      });

  // ---------- DOCS ----------
  /// Заглушка — загрузка документа (не реализована в UI)
  static Future<ApiResult> uploadDocument() async {
    return ApiResult(ok: false, error: 'Не реализовано');
  }
}
