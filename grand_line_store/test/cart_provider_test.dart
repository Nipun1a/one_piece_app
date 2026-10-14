// Unit tests for CartProvider
// Requirements: 6.3, 6.4, 6.5, 6.6, 6.7
// Parametrised boundary tests: Properties 6, 7, 8

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line_store/models/product.dart';
import 'package:grand_line_store/providers/cart_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Product makeProduct({
  int id = 1,
  String name = 'Test Product',
  double price = 10.0,
  int stock = 10,
}) =>
    Product(
      id: id,
      name: name,
      description: 'desc',
      price: price,
      category: 'Figures',
      imageUrl: 'https://example.com/img.png',
      stock: stock,
      rating: 4.5,
    );

void main() {
  // -------------------------------------------------------------------------
  // Group 1 – addItem
  // -------------------------------------------------------------------------
  group('CartProvider.addItem', () {
    test('adds a new product to an empty cart with quantity 1', () {
      final cart = CartProvider();
      final product = makeProduct(id: 1);

      cart.addItem(product);

      expect(cart.items.length, 1);
      expect(cart.items.first.product.id, 1);
      expect(cart.items.first.quantity, 1);
    });

    test('merges duplicate product — increments quantity instead of adding new line', () {
      final cart = CartProvider();
      final product = makeProduct(id: 1, stock: 5);

      cart.addItem(product);
      cart.addItem(product);

      expect(cart.items.length, 1);
      expect(cart.items.first.quantity, 2);
    });

    test('adding two different products creates two separate lines', () {
      final cart = CartProvider();
      final a = makeProduct(id: 1);
      final b = makeProduct(id: 2);

      cart.addItem(a);
      cart.addItem(b);

      expect(cart.items.length, 2);
    });

    test('increment at stock ceiling — quantity is clamped, not exceeded', () {
      final cart = CartProvider();
      final product = makeProduct(id: 1, stock: 2);

      // Add 3 times; stock is 2
      cart.addItem(product);
      cart.addItem(product);
      cart.addItem(product);

      expect(cart.items.first.quantity, 2);
      expect(cart.items.first.quantity, lessThanOrEqualTo(product.stock));
    });

    test('canIncrement returns false when quantity equals stock', () {
      final cart = CartProvider();
      final product = makeProduct(id: 1, stock: 1);

      cart.addItem(product); // quantity == stock == 1

      expect(cart.canIncrement(product.id), isFalse);
    });

    test('itemCount reflects total units across all lines', () {
      final cart = CartProvider();
      cart.addItem(makeProduct(id: 1, stock: 5));
      cart.addItem(makeProduct(id: 1, stock: 5)); // qty 2
      cart.addItem(makeProduct(id: 2, stock: 5)); // qty 1

      expect(cart.itemCount, 3);
    });
  });

  // -------------------------------------------------------------------------
  // Group 2 – decrementItem
  // -------------------------------------------------------------------------
  group('CartProvider.decrementItem', () {
    test('decrements quantity from 2 to 1', () {
      final cart = CartProvider();
      final product = makeProduct(id: 1, stock: 5);
      cart.addItem(product);
      cart.addItem(product);

      cart.decrementItem(product.id);

      expect(cart.items.first.quantity, 1);
    });

    test('decrement from 1 removes the item entirely', () {
      final cart = CartProvider();
      final product = makeProduct(id: 1, stock: 5);
      cart.addItem(product);

      cart.decrementItem(product.id);

      expect(cart.items, isEmpty);
      expect(cart.getItem(product.id), isNull);
    });

    test('decrement on non-existent product id is a no-op', () {
      final cart = CartProvider();
      cart.addItem(makeProduct(id: 1, stock: 5));

      cart.decrementItem(999);

      expect(cart.items.length, 1);
    });
  });

  // -------------------------------------------------------------------------
  // Group 3 – removeItem
  // -------------------------------------------------------------------------
  group('CartProvider.removeItem', () {
    test('removes a product that is in the cart', () {
      final cart = CartProvider();
      final product = makeProduct(id: 1, stock: 5);
      cart.addItem(product);

      cart.removeItem(product.id);

      expect(cart.items, isEmpty);
    });

    test('removing one product leaves others intact', () {
      final cart = CartProvider();
      cart.addItem(makeProduct(id: 1));
      cart.addItem(makeProduct(id: 2));

      cart.removeItem(1);

      expect(cart.items.length, 1);
      expect(cart.items.first.product.id, 2);
    });

    test('removeItem on non-existent id is a no-op', () {
      final cart = CartProvider();
      cart.addItem(makeProduct(id: 1));

      cart.removeItem(999);

      expect(cart.items.length, 1);
    });
  });

  // -------------------------------------------------------------------------
  // Group 4 – clear
  // -------------------------------------------------------------------------
  group('CartProvider.clear', () {
    test('clear empties a populated cart', () {
      final cart = CartProvider();
      cart.addItem(makeProduct(id: 1));
      cart.addItem(makeProduct(id: 2));

      cart.clear();

      expect(cart.items, isEmpty);
      expect(cart.itemCount, 0);
      expect(cart.isEmpty, isTrue);
    });

    test('clear on an already-empty cart is a no-op', () {
      final cart = CartProvider();

      cart.clear();

      expect(cart.items, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Group 5 – total / subtotal calculation
  // -------------------------------------------------------------------------
  group('CartProvider total calculation', () {
    test('total is 0 for an empty cart', () {
      final cart = CartProvider();
      expect(cart.total, 0.0);
      expect(cart.subtotal, 0.0);
    });

    test('total equals price × quantity for a single item', () {
      final cart = CartProvider();
      final product = makeProduct(id: 1, price: 15.0, stock: 5);
      cart.addItem(product);
      cart.addItem(product); // qty 2

      expect(cart.total, closeTo(30.0, 1e-10));
    });

    test('total equals sum of all line subtotals', () {
      final cart = CartProvider();
      cart.addItem(makeProduct(id: 1, price: 10.0, stock: 5)); // qty 1 → 10
      cart.addItem(makeProduct(id: 2, price: 20.0, stock: 5)); // qty 1 → 20

      expect(cart.total, closeTo(30.0, 1e-10));
    });

    test('subtotal and total are identical', () {
      final cart = CartProvider();
      cart.addItem(makeProduct(id: 1, price: 7.5, stock: 5));
      cart.addItem(makeProduct(id: 2, price: 12.5, stock: 5));

      expect(cart.total, cart.subtotal);
    });
  });

  // -------------------------------------------------------------------------
  // Group 6 – isEmpty / getItem helpers
  // -------------------------------------------------------------------------
  group('CartProvider helpers', () {
    test('isEmpty is true on a fresh cart', () {
      expect(CartProvider().isEmpty, isTrue);
    });

    test('isEmpty is false after adding an item', () {
      final cart = CartProvider();
      cart.addItem(makeProduct(id: 1));
      expect(cart.isEmpty, isFalse);
    });

    test('getItem returns null for missing product', () {
      final cart = CartProvider();
      expect(cart.getItem(1), isNull);
    });

    test('getItem returns the CartItem when present', () {
      final cart = CartProvider();
      final product = makeProduct(id: 1);
      cart.addItem(product);

      final item = cart.getItem(1);
      expect(item, isNotNull);
      expect(item!.product.id, 1);
    });
  });

  // =========================================================================
  // Parametrised boundary tests (Properties 6, 7, 8)
  // =========================================================================

  // -------------------------------------------------------------------------
  // Property 6 – Cart total equals sum of line subtotals
  //   Validates: Requirements 6.5
  //   For collections of products with arbitrary prices and quantities,
  //   cart.total == sum(price * qty).
  // -------------------------------------------------------------------------
  group('Property 6: cart.total == sum of line subtotals', () {
    // Deterministic random for reproducibility
    final rng = Random(42);

    // Build a cart from a list of (product, times-added) pairs and verify
    // the invariant holds.
    void runPropertyTest({
      required List<Product> products,
      required List<int> addCounts,
    }) {
      final cart = CartProvider();
      double expectedTotal = 0.0;

      for (var i = 0; i < products.length; i++) {
        final p = products[i];
        final times = addCounts[i];
        for (var j = 0; j < times; j++) {
          cart.addItem(p);
        }
        // Actual quantity after clamping
        final actualQty = cart.getItem(p.id)?.quantity ?? 0;
        expectedTotal += p.price * actualQty;
      }

      expect(
        cart.total,
        closeTo(expectedTotal, 1e-9),
        reason: 'total must equal sum of price × actual quantity',
      );

      // Cross-check: total == sum of each CartItem.subtotal
      final lineSum = cart.items.fold(0.0, (s, item) => s + item.subtotal);
      expect(cart.total, closeTo(lineSum, 1e-9));
    }

    test('Property 6 – single product, various quantities', () {
      for (var trial = 0; trial < 50; trial++) {
        final price = (rng.nextDouble() * 200).roundToDouble();
        final stock = rng.nextInt(20) + 1;
        final addCount = rng.nextInt(stock + 5) + 1;

        runPropertyTest(
          products: [makeProduct(id: 1, price: price, stock: stock)],
          addCounts: [addCount],
        );
      }
    });

    test('Property 6 – multi-product carts with random prices and quantities', () {
      for (var trial = 0; trial < 30; trial++) {
        final productCount = rng.nextInt(8) + 2; // 2..9 products
        final products = List.generate(
          productCount,
          (i) => makeProduct(
            id: i + 1,
            price: (rng.nextDouble() * 999 + 0.01).roundToDouble(),
            stock: rng.nextInt(15) + 1,
          ),
        );
        final addCounts =
            List.generate(productCount, (_) => rng.nextInt(20) + 1);

        runPropertyTest(products: products, addCounts: addCounts);
      }
    });

    test('Property 6 – zero-price products contribute nothing to total', () {
      final cart = CartProvider();
      // price = 0 is allowed; subtotal should be 0
      final p = makeProduct(id: 1, price: 0.0, stock: 5);
      cart.addItem(p);
      cart.addItem(p);
      expect(cart.total, 0.0);
    });
  });

  // -------------------------------------------------------------------------
  // Property 7 – Cart quantity is always bounded by product stock
  //   Validates: Requirements 6.6
  //   Sequences of addItem and extra calls must never exceed product.stock.
  // -------------------------------------------------------------------------
  group('Property 7: stored quantity never exceeds product.stock', () {
    final rng = Random(7);

    test('Property 7 – repeated addItem cannot exceed stock', () {
      for (var trial = 0; trial < 50; trial++) {
        final stock = rng.nextInt(10) + 1;
        final product = makeProduct(id: 1, stock: stock);
        final cart = CartProvider();
        final addTimes = rng.nextInt(30) + 1; // always > stock possible

        for (var j = 0; j < addTimes; j++) {
          cart.addItem(product);
        }

        final item = cart.getItem(product.id);
        if (item != null) {
          expect(
            item.quantity,
            lessThanOrEqualTo(stock),
            reason: 'quantity ${item.quantity} must not exceed stock $stock',
          );
        }
      }
    });

    test('Property 7 – mixed addItem on multiple products all stay within stock', () {
      for (var trial = 0; trial < 30; trial++) {
        final cart = CartProvider();
        final productCount = rng.nextInt(5) + 2;
        final products = List.generate(
          productCount,
          (i) => makeProduct(
            id: i + 1,
            stock: rng.nextInt(8) + 1,
          ),
        );

        // Issue random addItem calls
        for (var op = 0; op < 40; op++) {
          cart.addItem(products[rng.nextInt(productCount)]);
        }

        for (final p in products) {
          final item = cart.getItem(p.id);
          if (item != null) {
            expect(
              item.quantity,
              lessThanOrEqualTo(p.stock),
              reason: 'product ${p.id}: qty ${item.quantity} > stock ${p.stock}',
            );
          }
        }
      }
    });

    test('Property 7 – canIncrement returns false at stock ceiling', () {
      for (var trial = 0; trial < 30; trial++) {
        final stock = rng.nextInt(5) + 1;
        final product = makeProduct(id: 1, stock: stock);
        final cart = CartProvider();

        // Fill to exactly stock
        for (var j = 0; j < stock; j++) {
          cart.addItem(product);
        }

        expect(
          cart.canIncrement(product.id),
          isFalse,
          reason: 'canIncrement must be false when quantity == stock',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // Property 8 – Decrement from quantity 1 removes the item
  //   Validates: Requirements 6.7
  //   For any cart item at quantity 1, decrementItem results in the item
  //   being absent from the cart.
  // -------------------------------------------------------------------------
  group('Property 8: decrementItem at quantity 1 removes the item', () {
    final rng = Random(8);

    test('Property 8 – single item at qty 1 is removed after decrement', () {
      for (var trial = 0; trial < 50; trial++) {
        final id = rng.nextInt(1000) + 1;
        final product = makeProduct(id: id, stock: rng.nextInt(10) + 2);
        final cart = CartProvider();

        cart.addItem(product); // quantity is now exactly 1
        expect(cart.getItem(id)!.quantity, 1);

        cart.decrementItem(id);

        expect(
          cart.getItem(id),
          isNull,
          reason: 'item with id $id should be absent after decrement from qty 1',
        );
        expect(cart.items.where((i) => i.product.id == id), isEmpty);
      }
    });

    test('Property 8 – item among others at qty 1 is removed, others intact', () {
      for (var trial = 0; trial < 30; trial++) {
        final cart = CartProvider();
        final productCount = rng.nextInt(4) + 2; // 2..5 products

        for (var i = 0; i < productCount; i++) {
          cart.addItem(makeProduct(id: i + 1, stock: 5));
        }

        // Pick a random product to decrement from qty 1
        final targetId = rng.nextInt(productCount) + 1;
        final sizeBefore = cart.items.length;
        expect(cart.getItem(targetId)!.quantity, 1);

        cart.decrementItem(targetId);

        expect(
          cart.getItem(targetId),
          isNull,
          reason: 'targetId $targetId should be gone',
        );
        expect(
          cart.items.length,
          sizeBefore - 1,
          reason: 'one item should have been removed',
        );
      }
    });

    test('Property 8 – decremented item absence is reflected in isEmpty for single-item cart', () {
      for (var trial = 0; trial < 20; trial++) {
        final id = rng.nextInt(500) + 1;
        final cart = CartProvider();
        cart.addItem(makeProduct(id: id, stock: 3));

        cart.decrementItem(id);

        expect(cart.isEmpty, isTrue);
        expect(cart.itemCount, 0);
        expect(cart.total, 0.0);
      }
    });
  });
}
