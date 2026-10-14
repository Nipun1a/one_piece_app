import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/empty_state.dart';

/// Displays the user's shopping cart with item tiles and a checkout footer.
///
/// Uses [Consumer<CartProvider>] to react to cart state changes. When the
/// cart is empty an [EmptyState] is shown. When it has items a [ListView]
/// of [CartItemTile] widgets is rendered together with a sticky bottom bar
/// showing the total and a "Checkout" button.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<CartProvider>(
          builder: (context, cartProvider, _) {
            final count = cartProvider.itemCount;
            return Text(
              count > 0 ? 'Cart ($count item${count == 1 ? '' : 's'})' : 'Cart',
            );
          },
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          if (cartProvider.isEmpty) {
            return const EmptyState(
              message: 'Your cart is empty',
              icon: Icons.shopping_cart_outlined,
            );
          }

          return Column(
            children: [
              // Scrollable list of cart items
              Expanded(
                child: ListView.builder(
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartProvider.items[index];
                    return CartItemTile(
                      cartItem: cartItem,
                      onIncrement: () =>
                          cartProvider.addItem(cartItem.product),
                      onDecrement: () =>
                          cartProvider.decrementItem(cartItem.product.id),
                      onRemove: () =>
                          cartProvider.removeItem(cartItem.product.id),
                    );
                  },
                ),
              ),

              // Sticky checkout footer
              _CartFooter(
                subtotal: cartProvider.subtotal,
                total: cartProvider.total,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Sticky bottom bar showing the cart subtotal, order total, and a
/// "Checkout" button. Only rendered when the cart is non-empty, so the
/// Checkout button is always visible here (requirement 6.9).
class _CartFooter extends StatelessWidget {
  final double subtotal;
  final double total;

  const _CartFooter({required this.subtotal, required this.total});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Subtotal + Total labels (requirement 6.7)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      Text(
                        '\$${subtotal.toStringAsFixed(2)}',
                        style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Checkout button (requirement 6.9)
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/checkout'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
