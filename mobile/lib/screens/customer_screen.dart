import 'package:flutter/material.dart';
import '../theme.dart';
import 'new_order_screen.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';

class CustomerScreen extends StatelessWidget {
  const CustomerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Моё дело'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Профиль',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            children: [
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewOrderScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.red, AppColors.redDark],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: AppColors.red.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Column(children: [
                    Icon(Icons.add_circle_outline, size: 80, color: Colors.white),
                    SizedBox(height: 14),
                    Text('Оформить заказ',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 6),
                    Text('Нажмите и опишите задачу',
                        style: TextStyle(fontSize: 17, color: Colors.white)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.08),
                    border: Border.all(color: AppColors.blue.withOpacity(0.4), width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt, size: 40, color: AppColors.blue),
                      SizedBox(width: 16),
                      Text('Мои заказы',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.blue)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline, color: AppColors.blue, size: 24),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    'Опишите задачу — ИИ определит категорию и срочность.',
                    style: TextStyle(fontSize: 15),
                  )),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
