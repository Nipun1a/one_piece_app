import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import '../services/api_service.dart';

// ---------------------------------------------------------------------------
// AuthProvider
// ---------------------------------------------------------------------------

/// Manages authentication state for the Grand Line Store app.
///
/// Secure storage keys:
///   - `auth_token`  — raw JWT string
///   - `auth_user`   — JSON-encoded [User] object
///
/// On any error during [register] or [login] the exception message is placed
/// in [error] and listeners are notified. Errors are NOT re-thrown so the UI
/// only needs to watch the [error] field.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required ApiService apiService,
    FlutterSecureStorage? storage,
    this.onLogout,
  }) : _api = apiService,
       _storage = storage ?? const FlutterSecureStorage();

  // -------------------------------------------------------------------------
  // Dependencies
  // -------------------------------------------------------------------------

  final ApiService _api;
  final FlutterSecureStorage _storage;

  /// Optional callback invoked after a successful logout or forced logout
  /// (e.g. from a 401). Use this to clear other providers (e.g. CartProvider)
  /// and/or navigate to the login screen.
  final VoidCallback? onLogout;

  // -------------------------------------------------------------------------
  // Private state
  // -------------------------------------------------------------------------

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  String? _token; // in-memory cache so callers never need await storage.read

  // -------------------------------------------------------------------------
  // Public getters
  // -------------------------------------------------------------------------

  /// The currently logged-in user, or `null` when logged out.
  User? get user => _user;

  /// `true` while an async auth operation is in flight.
  bool get isLoading => _isLoading;

  /// The last error message, or `null` if no error occurred.
  String? get error => _error;

  /// `true` once [init] has completed (regardless of whether a user was found).
  bool get isInitialized => _isInitialized;

  /// `true` when a user is currently logged in.
  bool get isLoggedIn => _user != null;

  /// The in-memory cached JWT, or `null` when logged out.
  String? get token => _token;

  // -------------------------------------------------------------------------
  // Initialisation
  // -------------------------------------------------------------------------

  /// Restores a previous session from secure storage.
  ///
  /// Call this once from [SplashScreen] (or `main.dart`) before deciding which
  /// route to push. After this method returns, [isInitialized] is `true`.
  Future<void> init() async {
    try {
      final storedToken = await _storage.read(key: 'auth_token');
      if (storedToken != null) {
        _user = await _api.fetchCurrentUser();
        _token = storedToken;
      }
    } catch (_) {
      _user = null;
      _token = null;
      try {
        await _clearStorage();
      } catch (_) {
        /* Storage may be unavailable. */
      }
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // -------------------------------------------------------------------------
  // Register
  // -------------------------------------------------------------------------

  /// Registers a new account and persists the session.
  ///
  /// On success [user] and [token] are set and listeners are notified.
  /// On failure [error] is set and the exception is NOT re-thrown.
  Future<void> register(String name, String email, String password) async {
    if (_isLoading) return;
    _startLoading();

    try {
      final response = await _api.register(name, email, password);
      await _persistSession(response.token, response.user);
    } on ApiException catch (e) {
      _setError(e.message);
      return;
    } catch (e) {
      _setError('Unable to save your session. Please try again.');
      return;
    }
  }

  // -------------------------------------------------------------------------
  // Login
  // -------------------------------------------------------------------------

  /// Logs in with [email] and [password] and persists the session.
  ///
  /// On success [user] and [token] are set and listeners are notified.
  /// On failure [error] is set and the exception is NOT re-thrown.
  Future<void> login(String email, String password) async {
    if (_isLoading) return;
    _startLoading();

    try {
      final response = await _api.login(email, password);
      await _persistSession(response.token, response.user);
    } on ApiException catch (e) {
      _setError(e.message);
      return;
    } catch (e) {
      _setError('Unable to save your session. Please try again.');
      return;
    }
  }

  // -------------------------------------------------------------------------
  // Logout
  // -------------------------------------------------------------------------

  /// Clears the session and notifies listeners.
  ///
  /// Invokes [onLogout] (if provided) after clearing state, which can be used
  /// to clear the cart and/or navigate to the login screen.
  Future<void> logout() async {
    _user = null;
    _token = null;
    _error = null;
    notifyListeners();
    onLogout?.call();
    try {
      await _clearStorage();
    } catch (_) {
      _error = 'Could not remove the saved session. Please retry signing out.';
      notifyListeners();
    }
  }

  // -------------------------------------------------------------------------
  // 401 auto-logout (called by ApiService.onUnauthorized)
  // -------------------------------------------------------------------------

  /// Triggered by [ApiService] when any authenticated request returns 401.
  ///
  /// Behaves identically to [logout] so the UI is returned to the login screen
  /// without any explicit user action.
  void handleUnauthorized() {
    // Fire-and-forget: clear storage asynchronously but don't await here
    // so the synchronous 401 callback path is not blocked.
    logout();
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  void _startLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _setError(String message) {
    _isLoading = false;
    _error = message;
    notifyListeners();
  }

  /// Saves token + user to secure storage and updates in-memory state.
  Future<void> _persistSession(String token, User user) async {
    await Future.wait([
      _storage.write(key: 'auth_token', value: token),
      _storage.write(key: 'auth_user', value: jsonEncode(user.toJson())),
    ]);
    _token = token;
    _user = user;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Removes both auth keys from secure storage.
  Future<void> _clearStorage() async {
    await Future.wait([
      _storage.delete(key: 'auth_token'),
      _storage.delete(key: 'auth_user'),
    ]);
  }
}
