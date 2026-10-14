import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderTile extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderTile({required this.order, this.onTap, super.key});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = order.items.length;

    return Card(
      child: ListTile(
        title: Text(_formatDate(order.createdAt)),
        subtitle: Text('$itemCount ${itemCount == 1 ? 'item' : 'items'}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${order.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(order.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order.status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
