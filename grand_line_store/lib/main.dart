import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use a late variable so that the onUnauthorized closure can reference
  // authProvider before it is assigned — the closure is only *called* after
  // the variable is populated.
  late final AuthProvider authProvider;

  final apiService = ApiService(
    onUnauthorized: () => authProvider.handleUnauthorized(),
  );

  final cartProvider = CartProvider();

  authProvider = AuthProvider(
    apiService: apiService,
    onLogout: cartProvider.clear,
  );

  authProvider.init();

  final productProvider = ProductProvider(apiService: apiService);

  runApp(
    GrandLineApp(
      apiService: apiService,
      authProvider: authProvider,
      cartProvider: cartProvider,
      productProvider: productProvider,
    ),
  );
}

class GrandLineApp extends StatelessWidget {
  const GrandLineApp({
    super.key,
    required this.apiService,
    required this.authProvider,
    required this.cartProvider,
    required this.productProvider,
  });

  final ApiService apiService;
  final AuthProvider authProvider;
  final CartProvider cartProvider;
  final ProductProvider productProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
        ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
      ],
      child: MaterialApp(
        title: 'Grand Line Store',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // SplashScreen handles tryAutoLogin and navigates to /home or /login.
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const HomeScreen(),
          '/product': (_) => const ProductDetailScreen(),
          '/cart': (_) => const CartScreen(),
          '/checkout': (_) => const SessionGate(child: CheckoutScreen()),
          '/orders': (_) => const SessionGate(child: OrdersScreen()),
        },
      ),
    );
  }
}

class SessionGate extends StatelessWidget {
  const SessionGate({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      context.watch<AuthProvider>().isLoggedIn ? child : const LoginScreen();
}
