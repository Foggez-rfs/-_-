import 'package:flutter/material.dart';
import '../api.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/rating_dialog.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});
  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;
  String _role = 'customer';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    _role = (await Storage.getRole()) ?? 'customer';
    final r = await Api.myOrders();
    if (!mounted) return;
    setState(() => _loading = false);
    if (r.ok) {
      setState(() => _orders = (r.data['orders'] as List?) ?? []);
    } else {
      setState(() => _error = r.error);
    }
  }

  Future<void> _complete(int id) async {
    final r = await Api.completeOrder(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(r.ok ? '✅ Заказ завершён' : '❌ ${r.error}')),
    );
    if (r.ok) _load();
  }

  Future<void> _rate(int id, String executorName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => RatingDialog(
        orderId: id,
        executorName: executorName,
      ),
    );
    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⭐ Спасибо за оценку!')),
      );
      _load();
    }
  }

  String _catIcon(String c) {
    const m = {
      'сантехника': '🔧',
      'электрика': '⚡',
      'уборка': '🧹',
      'доставка': '📦',
      'сопровождение': '🚶',
      'ремонт': '🔨',
      'прочее': '📋',
    };
    return m[c] ?? '📋';
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return AppColors.orange;
      case 'accepted':
        return AppColors.blue;
      case 'completed':
        return AppColors.green;
      case 'cancelled':
        return AppColors.red;
      default:
        return AppColors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending':
        return '⏳ Ждёт исполнителя';
      case 'accepted':
        return '✅ Принят';
      case 'completed':
        return '🏆 Выполнен';
      case 'cancelled':
        return '❌ Отменён';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 70, color: AppColors.red),
                          const SizedBox(height: 16),
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 20),
                          ElevatedButton(
                              onPressed: _load, child: const Text('Повторить')),
                        ],
                      ),
                    ),
                  )
                : _orders.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('📭', style: TextStyle(fontSize: 80)),
                            SizedBox(height: 16),
                            Text('Заказов пока нет',
                                style: TextStyle(
                                    fontSize: 22, color: AppColors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final o = _orders[i];
                            final status = o['status'] as String? ?? 'pending';
                            final executor = o['executor'];
                            final executorName =
                                executor != null ? executor['first_name'] : null;
                            final reviewed = o['reviewed'] == true;

                            return Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Заголовок: категория + приоритет
                                    Row(children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppColors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${_catIcon(o['category'] ?? '')} ${o['category']}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.blue),
                                        ),
                                      ),
                                      if (o['priority'] == 1) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.red.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text('🔥 СРОЧНО',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.red)),
                                        ),
                                      ],
                                    ]),

                                    const SizedBox(height: 14),
                                    Text('${o['description']}',
                                        style: const TextStyle(fontSize: 18)),

                                    const SizedBox(height: 8),
                                    Row(children: [
                                      const Icon(Icons.location_on,
                                          size: 18, color: AppColors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text('${o['address'] ?? '—'}',
                                            style: const TextStyle(
                                                fontSize: 15,
                                                color: AppColors.grey)),
                                      ),
                                    ]),

                                    // Имя исполнителя
                                    if (executorName != null) ...[
                                      const SizedBox(height: 10),
                                      Row(children: [
                                        const Icon(Icons.person,
                                            size: 18, color: AppColors.blue),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Исполнитель: $executorName',
                                            style: const TextStyle(
                                                fontSize: 15,
                                                color: AppColors.blue,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ]),
                                    ],

                                    const SizedBox(height: 12),

                                    // Статус
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status)
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(_statusLabel(status),
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: _statusColor(status))),
                                    ),

                                    // Кнопка «Оценить работу» (заказчик)
                                    if (_role == 'customer' &&
                                        status == 'completed' &&
                                        !reviewed) ...[
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _rate(
                                              o['id'] as int,
                                              executorName ?? 'исполнитель'),
                                          icon: const Icon(Icons.star, size: 24),
                                          label: const Text('ОЦЕНИТЬ РАБОТУ'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.orange,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],

                                    // Уже оценён
                                    if (_role == 'customer' &&
                                        status == 'completed' &&
                                        reviewed) ...[
                                      const SizedBox(height: 12),
                                      Row(children: [
                                        const Icon(Icons.check_circle,
                                            color: AppColors.green, size: 20),
                                        const SizedBox(width: 6),
                                        const Text('Вы уже оценили работу',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.green)),
                                      ]),
                                    ],

                                    // Кнопка «Завершить» (исполнитель)
                                    if (_role == 'executor' &&
                                        status == 'accepted') ...[
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _complete(o['id'] as int),
                                          icon: const Icon(Icons.check_circle,
                                              size: 22),
                                          label: const Text('ЗАВЕРШИТЬ'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
