import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:grand_line_store/main.dart';
import 'package:grand_line_store/models/product.dart';
import 'package:grand_line_store/providers/auth_provider.dart';
import 'package:grand_line_store/providers/cart_provider.dart';
import 'package:grand_line_store/providers/product_provider.dart';
import 'package:grand_line_store/screens/home_screen.dart';
import 'package:grand_line_store/screens/login_screen.dart';
import 'package:grand_line_store/screens/register_screen.dart';
import 'package:grand_line_store/services/api_service.dart';
import 'package:grand_line_store/theme/app_theme.dart';

class PreviewApi extends ApiService {
  @override
  Future<List<Product>> fetchProducts({
    String? category,
    String? search,
  }) async => [
    for (var i = 1; i <= 4; i++)
      Product(
        id: i,
        name: [
          'Luffy — Gear Five',
          'The Straw Hat',
          'Zoro — Three Sword Style',
          'Grand Line Field Notes',
        ][i - 1],
        description: 'A keepsake for your collection.',
        price: 29.95 + i * 10,
        category: 'Figures',
        imageUrl: 'https://example.invalid/product.png',
        stock: 10,
        rating: 4.8,
      ),
  ];
}

void main() {
  for (final width in [390.0, 1280.0]) {
    for (final screen in ['home', 'login', 'register']) {
      testWidgets('$screen fits at width $width', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        if (const bool.fromEnvironment('CAPTURE_PREVIEWS')) {
          await tester.runAsync(() async {
            for (final font in {
              'Roboto': 'segoeui.ttf',
                'Ahem': 'segoeui.ttf',
              'Georgia': 'georgia.ttf',
            }.entries) {
              final loader = FontLoader(font.key)
                ..addFont(
                  File('C:/Windows/Fonts/${font.value}')
                      .readAsBytes()
                      .then((bytes) => ByteData.sublistView(bytes)),
                );
              await loader.load();
            }
          });
        }
        if (const bool.fromEnvironment('CAPTURE_PREVIEWS')) {
          await tester.runAsync(() async {
            final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
            await icons.load();
          });
        }
        final api = PreviewApi();
        final auth = AuthProvider(apiService: api);
        final products = ProductProvider(apiService: api);
        final key = GlobalKey();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<ApiService>.value(value: api),
              ChangeNotifierProvider.value(value: auth),
              ChangeNotifierProvider(create: (_) => CartProvider()),
              ChangeNotifierProvider.value(value: products),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: RepaintBoundary(
                key: key,
                child: screen == 'home'
                    ? const HomeScreen()
                    : screen == 'login'
                    ? const LoginScreen()
                    : const RegisterScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (screen == 'home') {
          await tester.scrollUntilVisible(
            find.text('Luffy — Gear Five'),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, 2000),
          );
          await tester.pumpAndSettle();
        }
        if (const bool.fromEnvironment('CAPTURE_PREVIEWS')) {
          await tester.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory('build/previews').create(recursive: true);
            await File('build/previews/$screen-${width.toInt()}.png')
                .writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox());
        auth.dispose();
        products.dispose();
      });
    }
  }
  testWidgets('protected content is hidden when signed out', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(apiService: PreviewApi()),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SessionGate(child: Text('Private orders')),
        ),
      ),
    );
    expect(find.text('Private orders'), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
