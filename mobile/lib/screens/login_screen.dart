import 'package:flutter/material.dart';
import '../services/api.dart';
import 'customer_screen.dart';
import 'executor_screen.dart';

/// Экран входа/регистрации.
/// Дизайн для пожилых: крупные элементы, контраст, простые подписи.
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
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _firstName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; });

    final res = _isRegister
        ? await Api.register(
            phone: _phone.text.trim(),
            password: _password.text,
            role: _role,
            firstName: _firstName.text.trim(),
          )
        : await Api.login(phone: _phone.text.trim(), password: _password.text);

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['ok'] == true) {
      final data = res['data'];
      final token = data['token'] as String?;
      if (token == null) {
        setState(() => _error = 'Сервер не вернул токен');
        return;
      }
      await Api.saveToken(token);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _role == 'executor'
              ? const ExecutorScreen()
              : const CustomerScreen(),
        ),
      );
    } else {
      setState(() => _error = res['error']?.toString() ?? 'Что-то пошло не так');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final accent = theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Моё дело',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6, size: 28),
            onPressed: widget.onToggleTheme,
            tooltip: 'Сменить тему',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // Логотип
              Icon(Icons.handshake, size: 96, color: primary),
              const SizedBox(height: 12),

              Text(
                'Помощь рядом',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                _isRegister ? 'Создайте новый аккаунт' : 'Войдите, чтобы продолжить',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 32),

              _Field(
                controller: _phone,
                label: 'Телефон',
                hint: '+7 900 123-45-67',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                primary: primary,
              ),
              const SizedBox(height: 16),

              _Field(
                controller: _password,
                label: 'Пароль',
                icon: Icons.lock_outline,
                obscure: _obscurePassword,
                primary: primary,
                suffix: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              if (_isRegister) ...[
                const SizedBox(height: 16),
                _Field(
                  controller: _firstName,
                  label: 'Как вас зовут?',
                  icon: Icons.person_outline,
                  primary: primary,
                ),
                const SizedBox(height: 24),

                Text(
                  'Кто вы?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _roleCard('Заказчик', 'Нужна помощь', Icons.elderly, 'customer', primary, accent)),
                    const SizedBox(width: 12),
                    Expanded(child: _roleCard('Исполнитель', 'Хочу помочь', Icons.engineering, 'executor', primary, accent)),
                  ],
                ),
              ],

              const SizedBox(height: 28),

              SizedBox(
                height: 64,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 26, width: 26,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(
                          _isRegister ? 'ЗАРЕГИСТРИРОВАТЬСЯ' : 'ВОЙТИ',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: _loading ? null : () => setState(() {
                  _isRegister = !_isRegister;
                  _error = null;
                }),
                child: Text(
                  _isRegister ? 'Уже есть аккаунт? Войти' : 'Нет аккаунта? Регистрация',
                  style: TextStyle(fontSize: 17, color: primary),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    border: Border.all(color: accent, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: accent, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: accent, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(String title, String subtitle, IconData icon, String value,
      Color primary, Color accent) {
    final selected = _role == value;
    return InkWell(
      onTap: () => setState(() => _role = value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: selected ? primary : Colors.grey.withOpacity(0.4),
            width: selected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: selected ? primary : Colors.grey),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? primary : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Универсальное поле с иконкой слева и опциональной иконкой справа.
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final Color primary;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 19),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 26),
        suffixIcon: suffix,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}
