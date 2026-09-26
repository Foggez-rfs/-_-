import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// ТОЧКА ВХОДА
// ============================================================

void main() => runApp(const MoeDeloApp());

class MoeDeloApp extends StatefulWidget {
  const MoeDeloApp({super.key});
  @override
  State<MoeDeloApp> createState() => _MoeDeloAppState();
}

class _MoeDeloAppState extends State<MoeDeloApp> {
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Моё дело',
      debugShowCheckedModeBanner: false,
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const SplashScreen(),
    );
  }

  ThemeData _theme(Brightness b) {
    final isDark = b == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E3A8A),
        primary: const Color(0xFF1E3A8A),
        secondary: const Color(0xFFDC2626),
        brightness: b,
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(60, 64),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFF1E3A8A).withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFF1E3A8A).withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
      ),
    );
  }
}

// ============================================================
// SPLASH — проверяет, есть ли сохранённый токен
// ============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    // Небольшая пауза, чтобы не мигало
    await Future.delayed(const Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    if (!mounted) return;

    if (token != null && token.isNotEmpty && role != null) {
      // Автологин
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => role == 'executor'
            ? const ExecutorScreen()
            : const CustomerScreen()),
      );
    } else {
      // К логину
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake, size: 100, color: Color(0xFF1E3A8A)),
            SizedBox(height: 20),
            Text('Моё дело', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 30),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// API — весь сетевой слой в одном месте
// ============================================================

class Api {
  static const String baseUrl = 'http://127.0.0.1:8080';
  static const Duration _timeout = Duration(seconds: 10);

  static String? _token;
  static String? _role;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _role = prefs.getString('role');
  }

  static Future<void> save(String token, String role) async {
    _token = token;
    _role = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('role', role);
  }

  static Future<void> logout() async {
    _token = null;
    _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
  }

  static String? get role => _role;

  static Map<String, String> get _h => {
    'Content-Type': 'application/json',
    if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
  };

  // --- Auth ---
  static Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String role,
    required String firstName,
  }) => _post('/auth/register', {
    'phone': phone,
    'password': password,
    'role': role,
    'first_name': firstName,
  });

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) => _post('/auth/login', {'phone': phone, 'password': password});

  // --- Orders ---
  static Future<Map<String, dynamic>> createOrder({
    required String description,
    required String address,
    double lat = 55.75,
    double lon = 37.62,
  }) => _post('/api/orders', {
    'description': description,
    'address': address,
    'lat': lat,
    'lon': lon,
  });

  static Future<Map<String, dynamic>> nearby({
    double lat = 55.75,
    double lon = 37.62,
    int radius = 5000,
  }) => _get('/api/orders/nearby?lat=$lat&lon=$lon&radius=$radius');

  static Future<Map<String, dynamic>> accept(int id) =>
      _post('/api/orders/$id/accept', {});

  // --- Внутренние методы ---
  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl$path'), headers: _h, body: jsonEncode(body))
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

  static Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl$path'), headers: _h)
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
    final text = utf8.decode(res.bodyBytes);
    try {
      final body = jsonDecode(text);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'ok': true, 'data': body};
      }
      final err = body is Map ? (body['error'] ?? 'Ошибка ${res.statusCode}') : 'Ошибка ${res.statusCode}';
      return {'ok': false, 'error': err.toString()};
    } catch (_) {
      return {'ok': false, 'error': 'Ответ сервера: $text'};
    }
  }
}

// ============================================================
// LOGIN / REGISTER
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  String _role = 'customer';
  bool _registerMode = false;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; });

    final res = _registerMode
        ? await Api.register(
            phone: _phone.text.trim(),
            password: _pass.text,
            role: _role,
            firstName: _name.text.trim(),
          )
        : await Api.login(phone: _phone.text.trim(), password: _pass.text);

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['ok'] == true) {
      final data = res['data'] as Map<String, dynamic>;
      final token = data['token'] as String?;
      final serverRole = (data['role'] as String?) ?? _role;
      if (token == null || token.isEmpty) {
        setState(() => _error = 'Сервер не вернул токен');
        return;
      }
      await Api.save(token, serverRole);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => serverRole == 'executor'
            ? const ExecutorScreen()
            : const CustomerScreen()),
      );
    } else {
      setState(() => _error = res['error']?.toString() ?? 'Ошибка');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final accent = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(title: const Text('Моё дело')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Icon(Icons.handshake, size: 90, color: primary),
              const SizedBox(height: 10),
              Text('Помощь рядом',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primary)),
              const SizedBox(height: 30),

              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 19),
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  hintText: '+7 900 123-45-67',
                  prefixIcon: Icon(Icons.phone, size: 26),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _pass,
                obscureText: _obscure,
                style: const TextStyle(fontSize: 19),
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: const Icon(Icons.lock_outline, size: 26),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              if (_registerMode) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _name,
                  style: const TextStyle(fontSize: 19),
                  decoration: const InputDecoration(
                    labelText: 'Имя',
                    prefixIcon: Icon(Icons.person_outline, size: 26),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Кто вы?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _roleBtn('Заказчик', Icons.elderly, 'customer', primary)),
                    const SizedBox(width: 12),
                    Expanded(child: _roleBtn('Исполнитель', Icons.engineering, 'executor', primary)),
                  ],
                ),
              ],

              const SizedBox(height: 26),

              SizedBox(
                height: 64,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const SizedBox(height: 26, width: 26,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(_registerMode ? 'ЗАРЕГИСТРИРОВАТЬСЯ' : 'ВОЙТИ',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading ? null : () => setState(() {
                  _registerMode = !_registerMode;
                  _error = null;
                }),
                child: Text(
                  _registerMode ? 'Уже есть аккаунт? Войти' : 'Нет аккаунта? Регистрация',
                  style: const TextStyle(fontSize: 17),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    border: Border.all(color: accent, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline, color: accent, size: 24),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: TextStyle(color: accent, fontSize: 15))),
                  ]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleBtn(String label, IconData icon, String value, Color primary) {
    final selected = _role == value;
    return InkWell(
      onTap: () => setState(() => _role = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(0.1) : null,
          border: Border.all(
            color: selected ? primary : Colors.grey.withOpacity(0.4),
            width: selected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Icon(icon, size: 36, color: selected ? primary : Colors.grey),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(
            fontSize: 15,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? primary : null,
          )),
        ]),
      ),
    );
  }
}

// ============================================================
// CUSTOMER SCREEN
// ============================================================

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});
  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final _desc = TextEditingController();
  final _addr = TextEditingController();
  bool _loading = false;
  String? _result;
  Color _resultColor = Colors.green;

  Future<void> _create() async {
    if (_desc.text.trim().isEmpty) {
      setState(() { _result = 'Введите описание'; _resultColor = Colors.red; });
      return;
    }
    setState(() { _loading = true; _result = null; });

    final res = await Api.createOrder(
      description: _desc.text.trim(),
      address: _addr.text.trim().isEmpty ? 'адрес не указан' : _addr.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['ok'] == true) {
      final d = res['data'];
      setState(() {
        _result = '✅ Заказ создан!\nКатегория: ${d['category']}\nПриоритет: ${d['priority']}';
        _resultColor = Colors.green;
      });
      _desc.clear();
      _addr.clear();
    } else {
      setState(() { _result = '❌ ${res['error']}'; _resultColor = Colors.red; });
    }
  }

  Future<void> _logout() async {
    await Api.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформить заказ'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Выйти'),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Что нужно сделать?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _desc,
              maxLines: 4,
              style: const TextStyle(fontSize: 19),
              decoration: const InputDecoration(
                hintText: 'Например: прорвало кран на кухне',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addr,
              style: const TextStyle(fontSize: 19),
              decoration: const InputDecoration(labelText: 'Адрес'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 64,
              child: ElevatedButton(
                onPressed: _loading ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent, foregroundColor: Colors.white),
                child: _loading
                    ? const SizedBox(height: 26, width: 26,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('ОФОРМИТЬ ЗАКАЗ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _resultColor.withOpacity(0.1),
                  border: Border.all(color: _resultColor, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_result!, style: TextStyle(fontSize: 17, color: _resultColor)),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

// ============================================================
// EXECUTOR SCREEN
// ============================================================

class ExecutorScreen extends StatefulWidget {
  const ExecutorScreen({super.key});
  @override
  State<ExecutorScreen> createState() => _ExecutorScreenState();
}

class _ExecutorScreenState extends State<ExecutorScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await Api.nearby(radius: 5000);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res['ok'] == true) {
      final data = res['data'];
      setState(() => _orders = (data['orders'] as List?) ?? []);
    } else {
      setState(() => _error = res['error']?.toString());
    }
  }

  Future<void> _accept(int id) async {
    final res = await Api.accept(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['ok'] == true ? 'Заказ принят' : '${res['error']}'),
    ));
    _load();
  }

  Future<void> _logout() async {
    await Api.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final accent = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы рядом'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Обновить'),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Выйти'),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.error_outline, size: 60, color: accent),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 17, color: accent)),
                      const SizedBox(height: 20),
                      ElevatedButton(onPressed: _load, child: const Text('Повторить')),
                    ]),
                  ))
                : _orders.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('Заказов рядом нет',
                            style: TextStyle(fontSize: 20, color: Colors.grey)),
                        const SizedBox(height: 20),
                        ElevatedButton(onPressed: _load, child: const Text('Обновить')),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final o = _orders[i];
                            return Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('${o['category'] ?? '—'}',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primary)),
                                    ),
                                    const SizedBox(width: 8),
                                    if (o['priority'] == 1)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: accent.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text('СРОЧНО',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accent)),
                                      ),
                                  ]),
                                  const SizedBox(height: 12),
                                  Text('${o['description']}', style: const TextStyle(fontSize: 18)),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    const Icon(Icons.location_on, size: 18, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text('${o['address'] ?? '—'}',
                                        style: const TextStyle(fontSize: 15, color: Colors.grey))),
                                  ]),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: () => _accept(o['id'] as int),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accent, foregroundColor: Colors.white),
                                      child: const Text('ПРИНЯТЬ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
