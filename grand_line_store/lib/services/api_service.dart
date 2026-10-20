// ignore_for_file: prefer_initializing_formals
import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/order.dart';
import '../models/product.dart';
import '../models/user.dart';

// ---------------------------------------------------------------------------
// Typed exception for all non-2xx HTTP responses.
// ---------------------------------------------------------------------------

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ---------------------------------------------------------------------------
// Typed response for register / login.
// ---------------------------------------------------------------------------

class AuthResponse {
  final String token;
  final User user;

  const AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    token: json['token'] as String,
    user: User.fromJson(json['user'] as Map<String, dynamic>),
  );
}

// ---------------------------------------------------------------------------
// Request body for placeOrder.
// ---------------------------------------------------------------------------

class PlaceOrderRequest {
  final List<Map<String, dynamic>> items; // [{productId, quantity}]
  final String address;
  final String phone;

  const PlaceOrderRequest({
    required this.items,
    required this.address,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
    'items': items,
    'address': address,
    'phone': phone,
  };
}

// ---------------------------------------------------------------------------
// ApiService
// ---------------------------------------------------------------------------

class ApiService {
  // Public parameter names keep configuration usable outside this library.
  const ApiService({
    String? baseUrl,
    this.tokenStore = const FlutterSecureStorage(),
    this.onUnauthorized,
    }) : _baseUrl = baseUrl;

  final String? _baseUrl;
  String get baseUrl {
    if (_baseUrl != null) return _baseUrl;
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) {
      return configured.replaceFirst(RegExp(r'/$'), '');
    }
    if (kIsWeb) return '${Uri.base.scheme}://${Uri.base.host}:3000/api';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000/api'
        : 'http://localhost:3000/api';
  }

  Future<http.Response> _send(Future<http.Response> request) async {
    try {
      return await request.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const ApiException(
        0,
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        0,
        'Cannot reach the store. Check your connection and API address.',
      );
    }
  }

  final FlutterSecureStorage tokenStore;

  /// Called whenever the server returns 401. Typically wired to
  /// `AuthProvider.handleUnauthorized` so the app auto-logs out.
  final VoidCallback? onUnauthorized;

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Builds the request headers, optionally including the stored JWT.
  Future<Map<String, String>> _buildHeaders({bool auth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await tokenStore.read(key: 'auth_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Parses [response], invokes [parser] on success, or throws [ApiException].
  /// Also fires [onUnauthorized] on 401 before throwing.
  T _handleResponse<T>(
    http.Response response,
    T Function(dynamic json) parser, {
    bool authenticated = false,
  }) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      body = null;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return parser(body);
    }
    if (authenticated && response.statusCode == 401) {
      onUnauthorized?.call();
    }
    final message = (body is Map && body.containsKey('error'))
        ? body['error'].toString()
        : 'Request failed with status ${response.statusCode}';
    throw ApiException(response.statusCode, message);
  }

  // -------------------------------------------------------------------------
  // Auth
  // -------------------------------------------------------------------------

  Future<User> fetchCurrentUser() async {
    final response = await _send(
      http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: await _buildHeaders(auth: true),
      ),
    );
    return _handleResponse(
      response,
      (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }

  /// POST /api/auth/register → `{ token, user }`
  Future<AuthResponse> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await _send(
      http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: await _buildHeaders(),
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ),
    );
    return _handleResponse(
      response,
      (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// POST /api/auth/login → `{ token, user }`
  Future<AuthResponse> login(String email, String password) async {
    final response = await _send(
      http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: await _buildHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );
    return _handleResponse(
      response,
      (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  // -------------------------------------------------------------------------
  // Products
  // -------------------------------------------------------------------------

  /// GET /api/products[?category=X][&search=Y] → `List<Product>`
  Future<List<Product>> fetchProducts({
    String? category,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (category != null && category.isNotEmpty && category != 'All') {
      queryParams['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final uri = Uri.parse('$baseUrl/products')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final response = await _send(http.get(uri, headers: await _buildHeaders()));
    return _handleResponse(
      response,
      (json) => (json as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// GET /api/products/:id → `Product`
  Future<Product> fetchProduct(int id) async {
    final response = await _send(
      http.get(
        Uri.parse('$baseUrl/products/$id'),
        headers: await _buildHeaders(),
      ),
    );
    return _handleResponse(
      response,
      (json) => Product.fromJson(json as Map<String, dynamic>),
    );
  }

  // -------------------------------------------------------------------------
  // Orders (authenticated)
  // -------------------------------------------------------------------------

  /// POST /api/orders with `Authorization: Bearer <token>` → `Order`
  Future<Order> placeOrder(PlaceOrderRequest request) async {
    final response = await _send(
      http.post(
        Uri.parse('$baseUrl/orders'),
        headers: await _buildHeaders(auth: true),
        body: jsonEncode(request.toJson()),
      ),
    );
    return _handleResponse(
      response,
      (json) => Order.fromJson(json as Map<String, dynamic>),
      authenticated: true,
    );
  }

  /// GET /api/orders with `Authorization: Bearer <token>` → `List<Order>`
  Future<List<Order>> fetchOrders() async {
    final response = await _send(
      http.get(
        Uri.parse('$baseUrl/orders'),
        headers: await _buildHeaders(auth: true),
      ),
    );
    return _handleResponse(
      response,
      (json) => (json as List)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList(),
      authenticated: true,
    );
  }
}
