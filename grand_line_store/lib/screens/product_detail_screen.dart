import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';

/// Full product detail screen.
///
/// Expects a [Product] passed via route arguments:
/// ```dart
/// Navigator.pushNamed(context, '/product', arguments: product);
/// ```
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  void _increment(Product product) {
    if (_quantity < product.stock) {
      setState(() => _quantity++);
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _addToCart(BuildContext context, Product product) {
    final cart = context.read<CartProvider>();

    // addItem increments by 1 each call; call it _quantity times.
    for (var i = 0; i < _quantity; i++) {
      cart.addItem(product);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${product.name} (×$_quantity) added to cart!',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product =
        ModalRoute.of(context)!.settings.arguments as Product;

    final theme = Theme.of(context);
    final inStock = product.stock > 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar with hero image ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-image-${product.id}',
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Detail content ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Price
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Category chip
                  Chip(
                    label: Text(product.category),
                    avatar: const Icon(Icons.label_outline, size: 16),
                    backgroundColor:
                        theme.colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),

                  const SizedBox(height: 12),

                  // Star rating
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 22),
                      const SizedBox(width: 4),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ 5.0',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stock indicator
                  _StockIndicator(stock: product.stock),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom bar: quantity selector + Add to Cart ────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Quantity selector
              _QuantitySelector(
                quantity: _quantity,
                onDecrement: _decrement,
                onIncrement: () => _increment(product),
                atMax: _quantity >= product.stock,
                disabled: !inStock,
              ),

              const SizedBox(width: 16),

              // Add to Cart button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: inStock
                      ? () => _addToCart(context, product)
                      : null,
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: Text(inStock ? 'Add to Cart' : 'Out of Stock'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private helper widgets ───────────────────────────────────────────────────

class _StockIndicator extends StatelessWidget {
  const _StockIndicator({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final inStock = stock > 0;
    final color = inStock ? Colors.green.shade700 : Colors.red.shade600;
    final icon = inStock ? Icons.check_circle_outline : Icons.cancel_outlined;
    final label = inStock ? 'In Stock ($stock available)' : 'Out of Stock';

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.atMax,
    required this.disabled,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool atMax;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement (–)
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: (disabled || quantity <= 1) ? null : onDecrement,
            splashRadius: 20,
            tooltip: 'Decrease quantity',
          ),

          // Current quantity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$quantity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Increment (+)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: (disabled || atMax) ? null : onIncrement,
            splashRadius: 20,
            tooltip: 'Increase quantity',
          ),
        ],
      ),
    );
  }
}
