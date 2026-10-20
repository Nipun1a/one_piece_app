// Tests for AuthProvider.
//
// Requirements: 2.7, 9.1, 9.2, 9.3, 9.4
//
// Stubs are hand-written to avoid code generation. No mockito or build_runner.

import 'dart:convert';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line_store/models/user.dart';
import 'package:grand_line_store/providers/auth_provider.dart';
import 'package:grand_line_store/services/api_service.dart';

// ---------------------------------------------------------------------------
// Fake FlutterSecureStorage
// ---------------------------------------------------------------------------

/// In-memory stand-in for FlutterSecureStorage. Stores key/value pairs in a
/// plain Map so tests never touch the platform channel.
class FakeSecureStorage implements FlutterSecureStorage {
  FakeSecureStorage([Map<String, String>? initial])
    : _store = Map<String, String>.from(initial ?? {});

  final Map<String, String> _store;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store.remove(key);

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store.clear();

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => Map<String, String>.unmodifiable(_store);

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store.containsKey(key);

  // ---- unused members — fall back to noSuchMethod -------------------------

  @override
  AndroidOptions get aOptions => const AndroidOptions();

  @override
  IOSOptions get iOptions => const IOSOptions();

  @override
  LinuxOptions get lOptions => const LinuxOptions();

  @override
  MacOsOptions get mOptions => const MacOsOptions();

  @override
  WebOptions get webOptions => const WebOptions();

  @override
  WindowsOptions get wOptions => const WindowsOptions();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Fake ApiService
// ---------------------------------------------------------------------------

/// A do-nothing ApiService stub. AuthProvider only calls the API during
/// register/login, which these tests don't exercise — they test init and
/// handleUnauthorized, both of which bypass the API entirely.
class FakeApiService extends ApiService {
  const FakeApiService() : super(baseUrl: 'http://fake.invalid');

  @override
  Future<User> fetchCurrentUser() async => _testUser;

  @override
  Future<AuthResponse> register(
    String name,
    String email,
    String password,
  ) async => throw UnimplementedError('FakeApiService: register not used here');

  @override
  Future<AuthResponse> login(String email, String password) async =>
      throw UnimplementedError('FakeApiService: login not used here');
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// A JSON-encoded User suitable for writing into fake storage.
const _testUser = User(id: 1, name: 'Luffy', email: 'luffy@pirate.king');
final _testUserJson = jsonEncode(_testUser.toJson());
const _testToken = 'eyJhbGciOiJIUzI1NiJ9.test.token';

/// Creates an [AuthProvider] whose storage is pre-populated with a valid
/// token and user, simulating a previous successful login.
AuthProvider _providerWithStoredToken({VoidCallback? onLogout}) {
  final storage = FakeSecureStorage({
    'auth_token': _testToken,
    'auth_user': _testUserJson,
  });
  return AuthProvider(
    apiService: const FakeApiService(),
    storage: storage,
    onLogout: onLogout,
  );
}

/// Creates an [AuthProvider] whose storage is empty (no prior session).
AuthProvider _providerWithoutStoredToken({VoidCallback? onLogout}) {
  return AuthProvider(
    apiService: const FakeApiService(),
    storage: FakeSecureStorage(),
    onLogout: onLogout,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

class ExpiredApiService extends FakeApiService {
  @override
  Future<User> fetchCurrentUser() async =>
      throw const ApiException(401, 'Expired');
}

class UnavailableStorage extends FakeSecureStorage {
  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw Exception('Storage locked');
}

void main() {
  test('expired server session is removed instead of restored', () async {
    final storage = FakeSecureStorage({
      'auth_token': _testToken,
      'auth_user': _testUserJson,
    });
    final provider = AuthProvider(
      apiService: ExpiredApiService(),
      storage: storage,
    );
    await provider.init();
    expect(provider.isInitialized, isTrue);
    expect(provider.isLoggedIn, isFalse);
    expect(await storage.read(key: 'auth_token'), isNull);
  });
  test('storage failure does not block app startup', () async {
    final provider = AuthProvider(
      apiService: const FakeApiService(),
      storage: UnavailableStorage(),
    );
    await provider.init();
    expect(provider.isInitialized, isTrue);
    expect(provider.isLoggedIn, isFalse);
  });
  group('AuthProvider', () {
    // -----------------------------------------------------------------------
    // init() / tryAutoLogin — stored token present
    // -----------------------------------------------------------------------

    group('init() with stored token', () {
      test('isLoggedIn becomes true after init', () async {
        final provider = _providerWithStoredToken();
        expect(
          provider.isLoggedIn,
          isFalse,
          reason: 'should start logged-out before init',
        );

        await provider.init();

        expect(provider.isLoggedIn, isTrue);
      });

      test('token is restored from storage', () async {
        final provider = _providerWithStoredToken();
        await provider.init();

        expect(provider.token, equals(_testToken));
      });

      test('user is restored from storage', () async {
        final provider = _providerWithStoredToken();
        await provider.init();

        expect(provider.user, isNotNull);
        expect(provider.user!.id, equals(1));
        expect(provider.user!.name, equals('Luffy'));
        expect(provider.user!.email, equals('luffy@pirate.king'));
      });

      test('isInitialized is true after init', () async {
        final provider = _providerWithStoredToken();
        await provider.init();

        expect(provider.isInitialized, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // init() / tryAutoLogin — no stored token
    // -----------------------------------------------------------------------

    group('init() without stored token', () {
      test('isLoggedIn remains false after init', () async {
        final provider = _providerWithoutStoredToken();
        await provider.init();

        expect(provider.isLoggedIn, isFalse);
      });

      test('token stays null after init', () async {
        final provider = _providerWithoutStoredToken();
        await provider.init();

        expect(provider.token, isNull);
      });

      test('user stays null after init', () async {
        final provider = _providerWithoutStoredToken();
        await provider.init();

        expect(provider.user, isNull);
      });

      test('isInitialized is true even when no session found', () async {
        final provider = _providerWithoutStoredToken();
        await provider.init();

        expect(provider.isInitialized, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // handleUnauthorized — clears token and fires navigation callback
    // -----------------------------------------------------------------------

    group('handleUnauthorized()', () {
      test('clears the in-memory token', () async {
        final provider = _providerWithStoredToken();
        await provider.init();
        expect(
          provider.token,
          isNotNull,
          reason: 'pre-condition: token was loaded',
        );

        provider.handleUnauthorized();
        // handleUnauthorized delegates to logout() which is async, but the
        // Future completes on the next microtask. pumpEventQueue drains it.
        await Future<void>.delayed(Duration.zero);

        expect(provider.token, isNull);
      });

      test('sets isLoggedIn to false', () async {
        final provider = _providerWithStoredToken();
        await provider.init();
        expect(
          provider.isLoggedIn,
          isTrue,
          reason: 'pre-condition: user is logged in',
        );

        provider.handleUnauthorized();
        await Future<void>.delayed(Duration.zero);

        expect(provider.isLoggedIn, isFalse);
      });

      test('invokes the onLogout navigation callback', () async {
        bool callbackInvoked = false;
        final provider = _providerWithStoredToken(
          onLogout: () => callbackInvoked = true,
        );
        await provider.init();

        provider.handleUnauthorized();
        await Future<void>.delayed(Duration.zero);

        expect(callbackInvoked, isTrue);
      });

      test('does not invoke callback when no onLogout is provided', () async {
        // Should complete without error even when onLogout is null.
        final provider = _providerWithStoredToken();
        await provider.init();

        expect(() async {
          provider.handleUnauthorized();
          await Future<void>.delayed(Duration.zero);
        }, returnsNormally);
      });
    });
  });
}
