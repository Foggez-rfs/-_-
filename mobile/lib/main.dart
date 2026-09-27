import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const MoeDeloApp());

class MoeDeloApp extends StatelessWidget {
  const MoeDeloApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Моё дело',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFFDC2626),
        ),
        useMaterial3: true,
      ),
      home: const StartScreen(),
    );
  }
}

// ============================================================
// START — решает: открыть Setup или WebView
// ============================================================
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});
  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('server_url');
    if (!mounted) return;
    if (url != null && url.isNotEmpty) {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => WebViewScreen(url: url)));
    } else {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const SetupScreen()));
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

// ============================================================
// SETUP — ввод URL сервера
// ============================================================
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _save() async {
    var url = _controller.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Введите адрес сервера');
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      setState(() => _error = 'Некорректный адрес');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
    if (!mounted) return;
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => WebViewScreen(url: url)));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final accent = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка сервера'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(Icons.cloud_outlined, size: 80, color: primary),
              const SizedBox(height: 16),
              Text('Подключение к серверу',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primary)),
              const SizedBox(height: 8),
              Text('Введите адрес сервера «Моё дело»',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 28),

              TextField(
                controller: _controller,
                keyboardType: TextInputType.url,
                autocorrect: false,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Адрес сервера',
                  hintText: 'https://xxx.trycloudflare.com',
                  prefixIcon: const Icon(Icons.link, size: 26),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                ),
                onSubmitted: (_) => _save(),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
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

              const SizedBox(height: 28),

              SizedBox(
                height: 64,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check, size: 26),
                  label: const Text('ПОДКЛЮЧИТЬСЯ',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.info_outline, size: 22, color: primary),
                      const SizedBox(width: 8),
                      Text('Примеры адресов',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primary)),
                    ]),
                    const SizedBox(height: 10),
                    const Text('• http://127.0.0.1:8080 — если сервер на этом же телефоне',
                        style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('• http://192.168.x.x:8080 — если сервер в той же Wi-Fi',
                        style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('• https://xxx.trycloudflare.com — через туннель Cloudflare',
                        style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('• https://moe-delo.ru — через VPS',
                        style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WEBVIEW — открывает сайт, кнопка смены сервера
// ============================================================
class WebViewScreen extends StatefulWidget {
  final String url;
  const WebViewScreen({super.key, required this.url});
  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF8FAFC))
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => setState(() => _progress = p),
        onPageStarted: (_) => setState(() { _hasError = false; _errorMessage = ''; }),
        onPageFinished: (_) => setState(() => _progress = 100),
        onWebResourceError: (err) {
          setState(() { _hasError = true; _errorMessage = err.description; });
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<bool> _onBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  Future<void> _changeServer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('server_url');
    if (!mounted) return;
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const SetupScreen()));
  }

  Future<void> _reload() async {
    setState(() { _hasError = false; _progress = 0; });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBack,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              if (_hasError) _buildError() else WebViewWidget(controller: _controller),

              // Кнопки в верхнем правом углу
              Positioned(
                top: 8, right: 8,
                child: Row(children: [
                  Material(
                    color: Colors.black.withOpacity(0.6),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
                      tooltip: 'Обновить',
                      onPressed: _reload,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.black.withOpacity(0.6),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white, size: 22),
                      tooltip: 'Сменить сервер',
                      onPressed: _changeServer,
                    ),
                  ),
                ]),
              ),

              if (_progress < 100 && !_hasError)
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    backgroundColor: Colors.transparent,
                    color: const Color(0xFFDC2626),
                    minHeight: 3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 80, color: Color(0xFFDC2626)),
            const SizedBox(height: 20),
            const Text('Не удалось подключиться',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(_errorMessage, style: const TextStyle(fontSize: 15, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Адрес: ${widget.url}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 56),
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _changeServer,
              icon: const Icon(Icons.settings),
              label: const Text('Сменить сервер', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
