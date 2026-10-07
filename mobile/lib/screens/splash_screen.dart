import 'package:flutter/material.dart';
import '../api.dart';
import '../storage.dart';
import '../theme.dart';
import 'setup_screen.dart';
import 'login_screen.dart';
import 'customer_screen.dart';
import 'executor_screen.dart';

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
    await Future.delayed(const Duration(milliseconds: 600));
    await Api.init();
    if (!mounted) return;

    final url = Api.baseUrl;
    final token = await Storage.getToken();
    final role = await Storage.getRole();

    if (url == null || url.isEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SetupScreen()));
    } else if (token != null && role != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => role == 'executor' ? const ExecutorScreen() : const CustomerScreen(),
      ));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🤝', style: TextStyle(fontSize: 100)),
            SizedBox(height: 20),
            Text('Моё дело', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.blue)),
            SizedBox(height: 30),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
