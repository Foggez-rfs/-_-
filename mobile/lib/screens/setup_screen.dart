import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import 'login_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_ctrl.text.trim().isEmpty) {
      setState(() => _error = 'Введите адрес сервера');
      return;
    }
    await Api.setBaseUrl(_ctrl.text);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _preset(String url) => setState(() {
    _ctrl.text = url;
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройка сервера')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.cloud_outlined, size: 80, color: AppColors.blue),
              const SizedBox(height: 16),
              const Text('Подключение к серверу',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.blue)),
              const SizedBox(height: 8),
              const Text('Введите адрес, где запущен бэкенд «Моё дело»',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.grey)),
              const SizedBox(height: 30),
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Адрес сервера',
                  hintText: 'http://192.168.1.100:8080',
                  prefixIcon: Icon(Icons.link, size: 26),
                ),
                onSubmitted: (_) => _save(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    border: Border.all(color: AppColors.red, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppColors.red, size: 24),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 15))),
                  ]),
                ),
              ],
              const SizedBox(height: 24),
              const Text('Быстрый выбор',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.grey)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _preset('http://127.0.0.1:8080'),
                icon: const Icon(Icons.phone_android, size: 22),
                label: const Text('Сервер на этом телефоне'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 54)),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _preset('http://192.168.1.100:8080'),
                icon: const Icon(Icons.wifi, size: 22),
                label: const Text('Сервер в той же Wi-Fi'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 54)),
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 64,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check, size: 26),
                  label: const Text('ПОДКЛЮЧИТЬСЯ'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
