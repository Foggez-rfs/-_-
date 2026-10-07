import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});
  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final _desc = TextEditingController();
  final _addr = TextEditingController();
  bool _loading = false;
  String? _result;
  Color _resultColor = AppColors.green;

  @override
  void dispose() {
    _desc.dispose();
    _addr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_desc.text.trim().isEmpty) {
      setState(() {
        _result = 'Опишите, что нужно сделать';
        _resultColor = AppColors.red;
      });
      return;
    }
    setState(() {
      _loading = true;
      _result = null;
    });

    final r = await Api.createOrder(
      description: _desc.text.trim(),
      address: _addr.text.trim().isEmpty ? 'адрес не указан' : _addr.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (r.ok) {
      final d = r.data;
      setState(() {
        _result = '✅ Заказ создан!\nКатегория: ${d['category']}\nПриоритет: ${d['priority']}';
        _resultColor = AppColors.green;
      });
      _desc.clear();
      _addr.clear();
    } else {
      setState(() {
        _result = '❌ ${r.error}';
        _resultColor = AppColors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый заказ')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Что нужно сделать?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _desc,
                maxLines: 4,
                style: const TextStyle(fontSize: 19),
                decoration: const InputDecoration(hintText: 'Например: прорвало кран на кухне'),
              ),
              const SizedBox(height: 20),
              const Text('Адрес',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _addr,
                style: const TextStyle(fontSize: 19),
                decoration: const InputDecoration(
                  hintText: 'Улица, дом, квартира',
                  prefixIcon: Icon(Icons.location_on, size: 26),
                ),
              ),
              const SizedBox(height: 24),
              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _resultColor.withOpacity(0.1),
                    border: Border.all(color: _resultColor, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(_result!,
                      style: TextStyle(fontSize: 17, color: _resultColor, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),
              ],
              SizedBox(
                height: 64,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: const Icon(Icons.send, size: 26),
                  label: Text(_loading ? 'Отправка…' : 'ОТПРАВИТЬ ЗАКАЗ'),
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
