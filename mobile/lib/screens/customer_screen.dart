import 'package:flutter/material.dart';
import '../services/api.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});
  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final _desc = TextEditingController();
  final _addr = TextEditingController();
  String? _status;
  bool _loading = false;

  Future<void> _create() async {
    if (_desc.text.trim().isEmpty) return;
    setState(() { _loading = true; _status = null; });
    try {
      final res = await Api.createOrder(
        description: _desc.text.trim(),
        address: _addr.text.trim().isEmpty ? 'адрес не указан' : _addr.text.trim(),
      );
      if (res['category'] != null) {
        setState(() => _status = '✅ Категория: ${res['category']}\nПриоритет: ${res['priority']}');
      } else {
        setState(() => _status = '❌ ${res['error'] ?? 'Ошибка'}');
      }
    } catch (e) {
      setState(() => _status = '❌ Сеть недоступна: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Оформить заказ')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Что нужно сделать?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _desc,
                maxLines: 4,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  hintText: 'Например: прорвало кран на кухне',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(18),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _addr,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: 'Адрес',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(18),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: _loading ? null : _create,
                icon: const Icon(Icons.send, size: 28),
                label: Text(_loading ? 'Отправляю...' : 'ОФОРМИТЬ ЗАКАЗ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
              if (_status != null) ...[
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_status!, style: const TextStyle(fontSize: 18)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
