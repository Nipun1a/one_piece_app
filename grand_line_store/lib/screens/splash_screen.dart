import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/loading_indicator.dart';

/// The app's initial route (`'/'`).
///
/// Displays a One Piece / nautical-themed splash while waiting for
/// [AuthProvider.isInitialized] to become `true`, then navigates:
///
/// - [AuthProvider.isLoggedIn] == `true`  → `/home`  (replace)
/// - [AuthProvider.isLoggedIn] == `false` → `/login` (replace)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Fade-in animation — completes within 1.2 s (well under the 1.5 s cap).
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();

    // Listen for AuthProvider initialisation. Because main.dart already calls
    // authProvider.init() before runApp, isInitialized is almost always true
    // immediately — but we guard with a listener so the splash is safe even if
    // called before init() completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isInitialized) {
        _navigate(auth);
      } else {
        auth.addListener(() {
          if (auth.isInitialized && mounted) {
            _navigate(auth);
          }
        });
      }
    });
  }

  void _navigate(AuthProvider auth) {
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      auth.isLoggedIn ? '/home' : '/login',
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Deep navy background matching the app's ocean theme.
      backgroundColor: const Color(0xFF0B2545),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ship-wheel icon as the app logo.
                const Icon(
                  Icons.anchor,
                  size: 100,
                  color: Color(0xFFF4B942), // gold accent
                ),
                const SizedBox(height: 32),
                // App title.
                const Text(
                  'Grand Line Store',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set sail for the best One Piece merch',
                  style: TextStyle(
                    color: Colors.white.withAlpha(179), // ~70 % opacity
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 60),
                // Loading indicator while auth initialises.
                const LoadingIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
