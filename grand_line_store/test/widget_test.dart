// Basic smoke test for the Grand Line Store app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grand_line_store/main.dart';
import 'package:grand_line_store/providers/auth_provider.dart';
import 'package:grand_line_store/providers/cart_provider.dart';
import 'package:grand_line_store/providers/product_provider.dart';
import 'package:grand_line_store/services/api_service.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    final apiService = ApiService();
    final cartProvider = CartProvider();
    final authProvider = AuthProvider(
      apiService: apiService,
      onLogout: cartProvider.clear,
    );
    final productProvider = ProductProvider(apiService: apiService);

    await tester.pumpWidget(
      GrandLineApp(
        apiService: apiService,
        authProvider: authProvider,
        cartProvider: cartProvider,
        productProvider: productProvider,
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
