import 'package:flutter/material.dart';
import '../services/api.dart';
import 'customer_screen.dart';
import 'executor_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const LoginScreen({super.key, required this.onToggleTheme});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _firstName = TextEditingController();
  String _role = 'customer';
  bool _isRegister = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = _isRegister
        ? await Api.register(
            phone: _phone.text.trim(),
            password: _password.text,
            role: _role,
            firstName: _firstName.text.trim(),
          )
        : await Api.login(phone: _phone.text.trim(), password: _password.text);

      if (res['token'] == null) {
        setState(() => _error = res['error'] ?? 'Ошибка');
        return;
      }

      await Api.saveToken(res['token']);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _role == 'executor'
            ? const ExecutorScreen()
            : const CustomerScreen(),
        ),
      );
    } catch (e) {
      setState(() => _error = 'Сеть недоступна: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Моё дело'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.onToggleTheme,
            tooltip: 'Сменить тему',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.handshake, size: 80, color: Color(0xFF1E3A8A)),
              const SizedBox(height: 12),
              const Text('Помощь рядом',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  hintText: '+7 900 123-45-67',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(18),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _password,
                obscureText: true,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(18),
                ),
              ),
              if (_isRegister) ...[
                const SizedBox(height: 15),
                TextField(
                  controller: _firstName,
                  style: const TextStyle(fontSize: 20),
                  decoration: const InputDecoration(
                    labelText: 'Имя',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(18),
                  ),
                ),
                const SizedBox(height: 15),
                const Text('Кто вы?', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _roleBtn('Заказчик', 'customer')),
                    const SizedBox(width: 10),
                    Expanded(child: _roleBtn('Исполнитель', 'executor')),
                  ],
                ),
              ],
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
                child: _loading
                  ? const SizedBox(height: 24, width: 24,
                      child: CircularProgressIndicator(color: Colors.white))
                  : Text(_isRegister ? 'ЗАРЕГИСТРИРОВАТЬСЯ' : 'ВОЙТИ'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _isRegister = !_isRegister),
                child: Text(
                  _isRegister ? 'Уже есть аккаунт? Войти' : 'Нет аккаунта? Регистрация',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 15),
                Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleBtn(String label, String value) {
    final selected = _role == value;
    return ElevatedButton(
      onPressed: () => setState(() => _role = value),
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
        foregroundColor: selected ? Colors.white : Colors.black87,
      ),
      child: Text(label),
    );
  }
}
