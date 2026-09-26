import 'package:flutter/material.dart';
import '../services/api.dart';

class ExecutorScreen extends StatefulWidget {
  const ExecutorScreen({super.key});
  @override
  State<ExecutorScreen> createState() => _ExecutorScreenState();
}

class _ExecutorScreenState extends State<ExecutorScreen> {
  List<dynamic> _orders = [];
  bool _loading = false;
  String? _error;

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Api.nearbyOrders();
      setState(() => _orders = res['orders'] ?? []);
    } catch (e) {
      setState(() => _error = 'Сеть недоступна: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _accept(int id) async {
    final res = await Api.acceptOrder(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message'] ?? res['error'] ?? 'Готово')),
    );
    _load();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы рядом'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 28), onPressed: _load),
        ],
      ),
      body: SafeArea(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Center(child: Text(_error!,
                style: const TextStyle(fontSize: 18, color: Colors.red)))
            : _orders.isEmpty
              ? const Center(
                  child: Text('Заказов рядом нет',
                      style: TextStyle(fontSize: 20, color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final o = _orders[i];
                    return Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${o['category']}',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3A8A))),
                            const SizedBox(height: 8),
                            Text('${o['description']}', style: const TextStyle(fontSize: 18)),
                            const SizedBox(height: 6),
                            Text('📍 ${o['address'] ?? '—'}',
                                style: const TextStyle(fontSize: 16, color: Colors.grey)),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _accept(o['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('ПРИНЯТЬ'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
