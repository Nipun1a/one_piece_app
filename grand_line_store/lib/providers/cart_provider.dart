import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  /// An unmodifiable view of the current cart items.
  List<CartItem> get items => List.unmodifiable(_items);

  /// Total number of individual units across all cart items.
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Sum of all line subtotals (alias for [total]).
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Sum of all line subtotals.
  double get total => subtotal;

  /// Whether the cart has no items.
  bool get isEmpty => _items.isEmpty;

  /// Returns the [CartItem] for the given [productId], or `null` if not in cart.
  CartItem? getItem(int productId) {
    try {
      return _items.firstWhere((item) => item.product.id == productId);
    } catch (_) {
      return null;
    }
  }

  /// Returns `true` if the item's current quantity is below the product's stock.
  bool canIncrement(int productId) {
    final item = getItem(productId);
    if (item == null) return false;
    return item.quantity < item.product.stock;
  }

  /// Adds [product] to the cart.
  ///
  /// If the product is already present, its quantity is incremented by 1
  /// (capped at [product.stock]). Otherwise a new [CartItem] with quantity 1
  /// is appended.
  void addItem(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      final current = _items[index];
      final newQty = (current.quantity + 1).clamp(1, product.stock);
      _items[index] = CartItem(product: current.product, quantity: newQty);
    } else {
      _items.add(CartItem(product: product, quantity: 1));
    }
    notifyListeners();
  }

  /// Removes the [CartItem] with the given [productId] from the cart entirely.
  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  /// Decrements the quantity of the item with [productId] by 1.
  ///
  /// If the current quantity is exactly 1, the item is removed from the cart.
  void decrementItem(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;

    final current = _items[index];
    if (current.quantity > 1) {
      _items[index] = CartItem(
        product: current.product,
        quantity: current.quantity - 1,
      );
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  /// Clears all items from the cart.
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
