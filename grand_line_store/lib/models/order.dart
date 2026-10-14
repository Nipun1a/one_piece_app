import 'order_item.dart';

class Order {
  final int id;
  final int userId;
  final double total;
  final String status;
  final String address;
  final String phone;
  final String createdAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.userId,
    required this.total,
    required this.status,
    required this.address,
    required this.phone,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      userId: json['userId'] as int,
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      createdAt: json['createdAt'] as String,
      items: (json['items'] as List)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
