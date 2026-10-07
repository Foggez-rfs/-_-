import 'package:flutter/material.dart';
import '../api.dart';
import '../storage.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Гость';
  String _role = '—';
  String _phone = '—';
  String _url = '—';
  double _rating = 5.0;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = await Storage.getName();
    final r = await Storage.getRole();
    final u = await Storage.getBaseUrl();
    final d = await Storage.isDarkMode();
    if (!mounted) return;
    setState(() {
      _name = (n?.isEmpty ?? true) ? 'Гость' : n!;
      _role = r == 'executor' ? '🔧 Исполнитель' : '🧓 Заказчик';
      _url = u ?? '—';
      _darkMode = d;
    });
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Выйти?'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Выйти',
                  style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok != true) return;
    await Api.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _changeUrl() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Сменить сервер?'),
        content: const Text('Вы выйдете из аккаунта и вернётесь к настройке.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Сменить')),
        ],
      ),
    );
    if (confirmed != true) return;
    await Api.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SetupScreen()),
      (route) => false,
    );
  }

  Future<void> _toggleDark(bool v) async {
    await Storage.setDarkMode(v);
    setState(() => _darkMode = v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(children: [
            // Аватар и имя
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(children: [
                Container(
                  width: 100, height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [AppColors.blue, AppColors.blueLight]),
                  ),
                  child: Center(
                    child: Text(
                      _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(_name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(_role,
                    style: const TextStyle(
                        fontSize: 16, color: AppColors.grey)),
              ]),
            ),

            const SizedBox(height: 20),

            // Сменить аккаунт
            _tile(
              icon: Icons.swap_horiz,
              title: 'Сменить аккаунт',
              onTap: _logout,
              color: AppColors.blue,
            ),
            const SizedBox(height: 10),

            // Сменить сервер
            _tile(
              icon: Icons.dns_outlined,
              title: 'Сменить сервер',
              onTap: _changeUrl,
              color: AppColors.blue,
            ),
            const SizedBox(height: 10),

            // Тёмная тема
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.dark_mode_outlined,
                    color: AppColors.blue, size: 26),
                const SizedBox(width: 12),
                const Expanded(
                    child: Text('Тёмная тема',
                        style: TextStyle(fontSize: 18))),
                Switch(value: _darkMode, onChanged: _toggleDark),
              ]),
            ),

            const SizedBox(height: 20),

            // URL сервера
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Сервер',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey)),
                    const SizedBox(height: 6),
                    Text(_url,
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis),
                  ]),
            ),

            const SizedBox(height: 20),

            // Выход
            SizedBox(
              height: 64,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 26),
                label: const Text('ВЫЙТИ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 18)),
          ),
          const Icon(Icons.arrow_forward_ios,
              size: 18, color: AppColors.grey),
        ]),
      ),
    );
  }
}
