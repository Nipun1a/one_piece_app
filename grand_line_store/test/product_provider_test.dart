// Unit tests for ProductProvider
// Requirements: 4.2, 4.3, 4.4, 4.8

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line_store/models/product.dart';
import 'package:grand_line_store/providers/product_provider.dart';
import 'package:grand_line_store/services/api_service.dart';

// ---------------------------------------------------------------------------
// Fake ApiService stub — avoids code generation
// ---------------------------------------------------------------------------

/// Tracks calls to [fetchProducts] and returns a configurable result.
class FakeApiService extends ApiService {
  FakeApiService() : super(baseUrl: 'http://localhost');

  /// If set, throws this exception on the next [fetchProducts] call.
  Object? nextError;

  /// The list returned by [fetchProducts] when [nextError] is null.
  List<Product> productsToReturn = [];

  /// Number of times [fetchProducts] was invoked.
  int fetchCallCount = 0;

  /// The last category passed to [fetchProducts].
  String? lastCategory;

  /// The last search query passed to [fetchProducts].
  String? lastSearch;

  /// Optional completer used to manually control when a fetch completes.
  Completer<List<Product>>? fetchCompleter;

  @override
  Future<List<Product>> fetchProducts({
    String? category,
    String? search,
  }) async {
    fetchCallCount++;
    lastCategory = category;
    lastSearch = search;

    if (nextError != null) {
      final err = nextError!;
      nextError = null;
      throw err;
    }

    if (fetchCompleter != null) {
      return fetchCompleter!.future;
    }

    return productsToReturn;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Product _makeProduct(int id) => Product(
      id: id,
      name: 'Product $id',
      description: 'Description $id',
      price: 9.99,
      category: 'Figures',
      imageUrl: 'https://example.com/$id.jpg',
      stock: 10,
      rating: 4.5,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeApiService fakeApi;
  late ProductProvider provider;

  setUp(() {
    fakeApi = FakeApiService();
    provider = ProductProvider(apiService: fakeApi);
  });

  tearDown(() {
    provider.dispose();
  });

  // -------------------------------------------------------------------------
  // Requirement 4.2 & 4.3 — Category filter sets selectedCategory and triggers fetch
  // -------------------------------------------------------------------------

  group('setCategory', () {
    test('updates selectedCategory to the requested value', () async {
      fakeApi.productsToReturn = [_makeProduct(1)];

      provider.setCategory('Figures');
      await Future<void>.delayed(Duration.zero); // let fetchProducts complete

      expect(provider.selectedCategory, 'Figures');
    });

    test('passes the chosen category to ApiService.fetchProducts', () async {
      fakeApi.productsToReturn = [_makeProduct(1)];

      provider.setCategory('Apparel');
      await Future<void>.delayed(Duration.zero);

      expect(fakeApi.lastCategory, 'Apparel');
    });

    test('triggers a fetch (fetchCallCount increments)', () async {
      fakeApi.productsToReturn = [];

      provider.setCategory('Posters');
      await Future<void>.delayed(Duration.zero);

      expect(fakeApi.fetchCallCount, 1);
    });

    test('selecting "All" sends null category to ApiService', () async {
      // First set a specific category...
      fakeApi.productsToReturn = [];
      provider.setCategory('Figures');
      await Future<void>.delayed(Duration.zero);

      // ...then switch back to "All"
      provider.setCategory('All');
      await Future<void>.delayed(Duration.zero);

      expect(provider.selectedCategory, 'All');
      expect(fakeApi.lastCategory, isNull);
    });

    test('products are updated with the API response', () async {
      final expected = [_makeProduct(1), _makeProduct(2)];
      fakeApi.productsToReturn = expected;

      provider.setCategory('Keychains');
      await Future<void>.delayed(Duration.zero);

      expect(provider.products, equals(expected));
    });

    test('isLoading is true during fetch, false afterward', () async {
      // Use a completer so we can inspect mid-flight state.
      final completer = Completer<List<Product>>();
      fakeApi.fetchCompleter = completer;

      final loadingStates = <bool>[];
      provider.addListener(() => loadingStates.add(provider.isLoading));

      provider.setCategory('Accessories');
      // isLoading should be true while awaiting
      await Future<void>.delayed(Duration.zero);
      expect(provider.isLoading, isTrue);

      completer.complete([]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.isLoading, isFalse);
      fakeApi.fetchCompleter = null;
    });
  });

  // -------------------------------------------------------------------------
  // Requirement 4.4 — Debounce: rapid setSearchQuery calls result in a single
  //                   fetch after 400 ms
  // -------------------------------------------------------------------------

  group('setSearchQuery debounce', () {
    test(
        'multiple rapid calls result in only one fetch after 400 ms',
        () async {
      fakeApi.productsToReturn = [];

      // Fire 5 rapid calls — none should trigger a fetch yet.
      provider.setSearchQuery('L');
      provider.setSearchQuery('Lu');
      provider.setSearchQuery('Luf');
      provider.setSearchQuery('Luffy');
      provider.setSearchQuery('Luffy!');

      // Immediately after: no fetch should have happened.
      expect(fakeApi.fetchCallCount, 0);

      // After the debounce window expires, exactly one fetch occurs.
      await Future<void>.delayed(const Duration(milliseconds: 450));

      expect(fakeApi.fetchCallCount, 1);
      expect(fakeApi.lastSearch, 'Luffy!');
    });

    test('searchQuery is updated to the latest value without waiting for debounce',
        () {
      provider.setSearchQuery('Zoro');
      expect(provider.searchQuery, 'Zoro');
    });

    test('search combined with category sends both params', () async {
      fakeApi.productsToReturn = [];

      // Set a category first.
      provider.setCategory('Figures');
      await Future<void>.delayed(Duration.zero);
      fakeApi.fetchCallCount = 0; // reset counter after category fetch

      // Then type a search query.
      provider.setSearchQuery('Luffy');
      await Future<void>.delayed(const Duration(milliseconds: 450));

      expect(fakeApi.lastCategory, 'Figures');
      expect(fakeApi.lastSearch, 'Luffy');
      expect(fakeApi.fetchCallCount, 1);
    });

    test('a new keystroke before 400 ms resets the timer', () async {
      fakeApi.productsToReturn = [];

      provider.setSearchQuery('R');
      // Wait 300 ms (less than debounce) — no fetch yet.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(fakeApi.fetchCallCount, 0);

      // Another keystroke resets the timer.
      provider.setSearchQuery('Ro');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      // Still within the new debounce window — no fetch.
      expect(fakeApi.fetchCallCount, 0);

      // Now let the full debounce expire.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(fakeApi.fetchCallCount, 1);
      expect(fakeApi.lastSearch, 'Ro');
    });
  });

  // -------------------------------------------------------------------------
  // Requirement 4.8 — Error state set on ApiException; cleared on retry
  // -------------------------------------------------------------------------

  group('error state and retry', () {
    test('sets error message when ApiException is thrown', () async {
      fakeApi.nextError = const ApiException(500, 'Server error');

      await provider.fetchProducts();

      expect(provider.error, 'Server error');
      expect(provider.isLoading, isFalse);
    });

    test('isLoading is false after an ApiException', () async {
      fakeApi.nextError = const ApiException(503, 'Unavailable');

      await provider.fetchProducts();

      expect(provider.isLoading, isFalse);
    });

    test('products remain empty when fetch fails', () async {
      fakeApi.nextError = const ApiException(500, 'Oops');

      await provider.fetchProducts();

      expect(provider.products, isEmpty);
    });

    test('retry clears error and re-fetches successfully', () async {
      // First: cause an error.
      fakeApi.nextError = const ApiException(500, 'Network failure');
      await provider.fetchProducts();
      expect(provider.error, isNotNull);

      // Second: configure a successful response and retry.
      fakeApi.productsToReturn = [_makeProduct(42)];
      await provider.retry();

      expect(provider.error, isNull);
      expect(provider.products, hasLength(1));
      expect(provider.products.first.id, 42);
    });

    test('retry passes null error state to listeners during re-fetch', () async {
      fakeApi.nextError = const ApiException(500, 'Fail');
      await provider.fetchProducts();

      // Error is set.
      expect(provider.error, isNotNull);

      // retry() triggers a fresh fetch; error should clear before the new
      // fetch result arrives.
      final errorsDuringRetry = <String?>[];
      provider.addListener(() => errorsDuringRetry.add(provider.error));

      fakeApi.productsToReturn = [];
      await provider.retry();

      // The first notification from retry's internal fetchProducts call sets
      // isLoading=true and error=null; the second finishes.
      expect(errorsDuringRetry, contains(null));
    });

    test('non-ApiException errors also populate the error field', () async {
      fakeApi.nextError = Exception('Unexpected crash');

      await provider.fetchProducts();

      expect(provider.error, isNotNull);
      expect(provider.error, contains('Unexpected crash'));
    });

    test('a successful retry after a general exception clears error', () async {
      fakeApi.nextError = Exception('Random failure');
      await provider.fetchProducts();
      expect(provider.error, isNotNull);

      fakeApi.productsToReturn = [_makeProduct(7)];
      await provider.retry();

      expect(provider.error, isNull);
      expect(provider.products, hasLength(1));
    });
  });
}
