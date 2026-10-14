import 'dart:convert';

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
  const ApiService({
    this.baseUrl = 'http://10.0.2.2:3000/api',
    this.tokenStore = const FlutterSecureStorage(),
    this.onUnauthorized,
  });

  final String baseUrl;
  final FlutterSecureStorage tokenStore;

  /// Called whenever the server returns 401. Typically wired to
  /// `AuthProvider.handleUnauthorized` so the app auto-logs out.
  final VoidCallback? onUnauthorized;

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Builds the request headers, optionally including the stored JWT.
  Future<Map<String, String>> _buildHeaders({bool auth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
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
    T Function(dynamic json) parser,
  ) {
    final dynamic body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return parser(body);
    }
    if (response.statusCode == 401) {
      onUnauthorized?.call();
    }
    final message = (body is Map && body.containsKey('error'))
        ? body['error'] as String
        : 'Request failed with status ${response.statusCode}';
    throw ApiException(response.statusCode, message);
  }

  // -------------------------------------------------------------------------
  // Auth
  // -------------------------------------------------------------------------

  /// POST /api/auth/register → `{ token, user }`
  Future<AuthResponse> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _buildHeaders(),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return _handleResponse(response, (json) => AuthResponse.fromJson(json as Map<String, dynamic>));
  }

  /// POST /api/auth/login → `{ token, user }`
  Future<AuthResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _buildHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response, (json) => AuthResponse.fromJson(json as Map<String, dynamic>));
  }

  // -------------------------------------------------------------------------
  // Products
  // -------------------------------------------------------------------------

  /// GET /api/products[?category=X][&search=Y] → `List<Product>`
  Future<List<Product>> fetchProducts({String? category, String? search}) async {
    final queryParams = <String, String>{};
    if (category != null && category.isNotEmpty && category != 'All') {
      queryParams['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final uri = Uri.parse('$baseUrl/products')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final response = await http.get(uri, headers: await _buildHeaders());
    return _handleResponse(
      response,
      (json) => (json as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// GET /api/products/:id → `Product`
  Future<Product> fetchProduct(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$id'),
      headers: await _buildHeaders(),
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
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: await _buildHeaders(auth: true),
      body: jsonEncode(request.toJson()),
    );
    return _handleResponse(
      response,
      (json) => Order.fromJson(json as Map<String, dynamic>),
    );
  }

  /// GET /api/orders with `Authorization: Bearer <token>` → `List<Order>`
  Future<List<Order>> fetchOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: await _buildHeaders(auth: true),
    );
    return _handleResponse(
      response,
      (json) => (json as List)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
