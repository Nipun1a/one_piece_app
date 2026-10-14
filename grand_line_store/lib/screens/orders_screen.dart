import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/order_tile.dart';

/// Displays the authenticated user's order history.
///
/// On mount it calls [ApiService.fetchOrders] and renders:
/// - [LoadingIndicator] while the request is in flight
/// - [EmptyState] with "No orders yet" when the list is empty
/// - An error widget with a Retry button on failure
/// - A [ListView] of [OrderTile]s on success
///
/// Requirements: 8.1, 8.2, 8.3, 8.4
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Fetch after the first frame so BuildContext is fully ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrders();
    });
  }

  // ---------------------------------------------------------------------------
  // Data fetching
  // ---------------------------------------------------------------------------

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await context.read<ApiService>().fetchOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Something went wrong. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Requirement 8.2 — loading state
    if (_isLoading) {
      return const LoadingIndicator();
    }

    // Requirement 8.4 — error state with Retry
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchOrders,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Requirement 8.3 — empty state
    if (_orders.isEmpty) {
      return const EmptyState(
        message: 'No orders yet',
        icon: Icons.receipt_long_outlined,
      );
    }

    // Requirement 8.1 — list of orders
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        return OrderTile(order: _orders[index]);
      },
    );
  }
}
