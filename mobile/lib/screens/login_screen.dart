import 'package:flutter/material.dart';
import '../api.dart';
import '../storage.dart';
import '../theme.dart';
import 'customer_screen.dart';
import 'executor_screen.dart';
import 'setup_screen.dart';

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
  bool _register = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _pass.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final phone = _phone.text.trim();
    final pass = _pass.text;
    final name = _name.text.trim();

    if (phone.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Заполните телефон и пароль');
      return;
    }
    if (pass.length < 4) {
      setState(() => _error = 'Пароль минимум 4 символа');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final r = _register
        ? await Api.register(phone: phone, password: pass, role: _role, firstName: name)
        : await Api.login(phone: phone, password: pass);

    if (!mounted) return;
    setState(() => _loading = false);

    if (r.ok) {
      final role = await Storage.getRole();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => role == 'executor' ? const ExecutorScreen() : const CustomerScreen(),
      ));
    } else {
      setState(() => _error = r.error ?? 'Что-то пошло не так');
    }
  }

  Future<void> _changeUrl() async {
    await Api.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SetupScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Моё дело'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), tooltip: 'Сменить сервер', onPressed: _changeUrl),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text('🤝', textAlign: TextAlign.center, style: TextStyle(fontSize: 90)),
              const SizedBox(height: 8),
              const Text('Помощь рядом',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.blue)),
              const SizedBox(height: 6),
              Text(
                _register ? 'Создайте новый аккаунт' : 'Войдите, чтобы продолжить',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.grey),
              ),
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
                obscureText: true,
                style: const TextStyle(fontSize: 19),
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: Icon(Icons.lock_outline, size: 26),
                ),
              ),
              if (_register) ...[
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
                Row(children: [
                  Expanded(child: _roleCard('Заказчик', Icons.elderly, 'customer')),
                  const SizedBox(width: 12),
                  Expanded(child: _roleCard('Исполнитель', Icons.engineering, 'executor')),
                ]),
              ],
              const SizedBox(height: 24),
              if (_error != null) ...[
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
                const SizedBox(height: 16),
              ],
              SizedBox(
                height: 64,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
                  child: _loading
                      ? const SizedBox(height: 26, width: 26, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(_register ? 'ЗАРЕГИСТРИРОВАТЬСЯ' : 'ВОЙТИ',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading ? null : () => setState(() { _register = !_register; _error = null; }),
                child: Text(
                  _register ? 'Уже есть аккаунт? Войти' : 'Нет аккаунта? Регистрация',
                  style: const TextStyle(fontSize: 17, color: AppColors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(String label, IconData icon, String value) {
    final selected = _role == value;
    return InkWell(
      onTap: () => setState(() => _role = value),
      borderRadius: BorderRadius.circular(AppSizes.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue.withOpacity(0.1) : null,
          border: Border.all(
            color: selected ? AppColors.blue : AppColors.grey.withOpacity(0.4),
            width: selected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radius),
        ),
        child: Column(children: [
          Icon(icon, size: 42, color: selected ? AppColors.blue : AppColors.grey),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(
            fontSize: 15,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? AppColors.blue : null,
          )),
        ]),
      ),
    );
  }
}
