import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  // -------------------------------------------------------------------------
  // Constants
  // -------------------------------------------------------------------------

  static const List<String> categories = [
    'All',
    'Figures',
    'Apparel',
    'Posters',
    'Keychains',
    'Accessories',
  ];

  static const Duration _debounceDuration = Duration(milliseconds: 400);

  // -------------------------------------------------------------------------
  // State
  // -------------------------------------------------------------------------

  final ApiService _apiService;

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  Timer? _debounce;

  ProductProvider({required this._apiService});

  // -------------------------------------------------------------------------
  // Getters
  // -------------------------------------------------------------------------

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  // -------------------------------------------------------------------------
  // Methods
  // -------------------------------------------------------------------------

  /// Fetches products from the API, applying the current category filter and
  /// search query. Updates [_isLoading] and [_error] accordingly.
  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _apiService.fetchProducts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the selected category and re-fetches the product list.
  void setCategory(String category) {
    _selectedCategory = category;
    fetchProducts();
  }

  /// Updates the search query with a 400 ms debounce before re-fetching.
  void setSearchQuery(String query) {
    _searchQuery = query;
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, fetchProducts);
  }

  /// Clears the current error and re-fetches the product list.
  Future<void> retry() {
    _error = null;
    return fetchProducts();
  }

  /// Clears the current error and notifies listeners.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
