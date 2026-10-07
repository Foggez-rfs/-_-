import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';

/// Диалог «Оцените работу»
class RatingDialog extends StatefulWidget {
  final int orderId;
  final String executorName;
  final VoidCallback? onRated;

  const RatingDialog({
    super.key,
    required this.orderId,
    required this.executorName,
    this.onRated,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _score = 5;
  final _comment = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final r = await Api.rateOrder(
      orderId: widget.orderId,
      score: _score,
      comment: _comment.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (r.ok) {
      Navigator.pop(context, true);
      widget.onRated?.call();
    } else {
      setState(() => _error = r.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 60, color: AppColors.orange),
            const SizedBox(height: 10),
            const Text('Оцените работу',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Исполнитель: ${widget.executorName}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.grey)),
            const SizedBox(height: 20),

            // Звёзды
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  onPressed: () => setState(() => _score = star),
                  icon: Icon(
                    star <= _score ? Icons.star : Icons.star_border,
                    size: 42,
                    color: AppColors.orange,
                  ),
                );
              }),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _comment,
              maxLines: 3,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Комментарий (необязательно)',
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: AppColors.red, fontSize: 14)),
            ],

            const SizedBox(height: 20),

            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 54),
                  ),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 54),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('ОТПРАВИТЬ'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
