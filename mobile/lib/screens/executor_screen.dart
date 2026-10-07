import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';

class ExecutorScreen extends StatefulWidget {
  const ExecutorScreen({super.key});
  @override
  State<ExecutorScreen> createState() => _ExecutorScreenState();
}

class _ExecutorScreenState extends State<ExecutorScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final r = await Api.nearbyOrders();
    if (!mounted) return;
    setState(() => _loading = false);
    if (r.ok) {
      setState(() => _orders = (r.data['orders'] as List?) ?? []);
    } else {
      setState(() => _error = r.error);
    }
  }

  Future<void> _accept(int id) async {
    final r = await Api.acceptOrder(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(r.ok ? '✅ Заказ принят' : '❌ ${r.error}')),
    );
    if (r.ok) _load();
  }

  String _catIcon(String c) {
    const m = {'сантехника':'🔧','электрика':'⚡','уборка':'🧹','доставка':'📦','сопровождение':'🚶','ремонт':'🔨','прочее':'📋'};
    return m[c] ?? '📋';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы рядом'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Мои заказы',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_outline, size: 70, color: AppColors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 20),
                      ElevatedButton(onPressed: _load, child: const Text('Повторить')),
                    ]),
                  ))
                : _orders.isEmpty
                    ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('📭', style: TextStyle(fontSize: 80)),
                        SizedBox(height: 16),
                        Text('Заказов рядом нет', style: TextStyle(fontSize: 22, color: AppColors.grey)),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final o = _orders[i];
                            return Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('${_catIcon(o['category'] as String? ?? '')} ${o['category']}',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.blue)),
                                    ),
                                    if (o['priority'] == 1) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppColors.red.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text('🔥 СРОЧНО',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.red)),
                                      ),
                                    ],
                                  ]),
                                  const SizedBox(height: 14),
                                  Text('${o['description']}', style: const TextStyle(fontSize: 18)),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    const Icon(Icons.location_on, size: 18, color: AppColors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text('${o['address'] ?? '—'}',
                                        style: const TextStyle(fontSize: 15, color: AppColors.grey))),
                                  ]),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () => _accept(o['id'] as int),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
                                      child: const Text('ПРИНЯТЬ',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
