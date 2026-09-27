import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// ⚠️ ЗАМЕНИ на IP телефона, где запущен сервер Termux.
/// - На том же телефоне: 127.0.0.1
/// - С другого устройства в Wi-Fi: IP из ifconfig (например 10.48.5.200)
const String BASE_URL = 'http://10.48.5.200:8080';

void main() {
  runApp(const MoeDeloApp());
}

class MoeDeloApp extends StatelessWidget {
  const MoeDeloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Моё дело',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFFDC2626),
        ),
      ),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});
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
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF8FAFC))
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => setState(() => _progress = p),
        onPageStarted: (_) => setState(() {
          _hasError = false;
          _errorMessage = '';
        }),
        onPageFinished: (_) => setState(() => _progress = 100),
        onWebResourceError: (err) {
          setState(() {
            _hasError = true;
            _errorMessage = err.description;
          });
        },
      ))
      ..loadRequest(Uri.parse(BASE_URL));
  }

  Future<bool> _onBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBack,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              if (_hasError)
                _buildError()
              else
                WebViewWidget(controller: _controller),

              // Полоса загрузки
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
            Text(_errorMessage,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Сервер: $BASE_URL',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            const Text('Проверьте, что бэкенд запущен в Termux:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SelectableText(
                'cd ~/moe-delo\ngo run cmd/server/main.go',
                style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() { _hasError = false; _progress = 0; });
                _controller.loadRequest(Uri.parse(BASE_URL));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 56),
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
