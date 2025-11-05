// ============================================================================
// PRODUCT PROVIDER
// ============================================================================
// This file contains Riverpod providers for product state management.
//
// RESPONSIBILITIES:
// - Manage product list state
// - Handle product loading
// - Handle pagination
// - Handle search
// - Handle category filtering
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kutuku/models/product.dart';
import 'package:kutuku/providers/auth_provider.dart'; // For apiClientProvider
import 'package:kutuku/services/product_service.dart';

// ============================================================================
// SERVICE PROVIDER
// ============================================================================

/// Provider for ProductService
///
/// WHAT IT DOES:
/// Creates a single instance of ProductService
///
/// DEPENDENCY:
/// Uses apiClientProvider to get the API client
final productServiceProvider = Provider<ProductService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductService(apiClient);
});

// ============================================================================
// PRODUCT LIST STATE PROVIDER
// ============================================================================

/// Provider for product list state
///
/// WHAT IT DOES:
/// Manages the list of products displayed in the UI
///
/// STATE TYPE: AsyncValue<List<Product>>
/// - loading: Fetching products
/// - data: Products loaded successfully
/// - error: Failed to load products
///
/// EXAMPLE USAGE:
/// ```dart
/// // In a widget
/// final productsState = ref.watch(productListProvider);
///
/// productsState.when(
///   loading: () => CircularProgressIndicator(),
///   data: (products) => ProductGrid(products: products),
///   error: (error, stack) => ErrorWidget(error: error),
/// );
/// ```
///
/// LOADING MORE PRODUCTS:
/// ```dart
/// ref.read(productListProvider.notifier).loadMore();
/// ```
final productListProvider =
    StateNotifierProvider<ProductNotifier, AsyncValue<List<Product>>>((ref) {
  final productService = ref.watch(productServiceProvider);
  return ProductNotifier(productService);
});

// ============================================================================
// PRODUCT NOTIFIER
// ============================================================================

/// State manager for product list
///
/// FEATURES:
/// - Load products with pagination
/// - Load more products (infinite scroll)
/// - Refresh products
/// - Track loading state
/// - Track pagination state
class ProductNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  // ==========================================================================
  // PROPERTIES
  // ==========================================================================

  /// The product service for API calls
  final ProductService _productService;

  /// Current pagination offset
  /// Example: If limit=10 and skip=20, we're on page 3
  int _skip = 0;

  /// Number of products to load per page
  /// Default: 10 products at a time
  final int _limit = 10;

  /// Total number of products available
  /// Used to know when we've loaded all products
  int _total = 0;

  /// Whether we're currently loading more products
  /// Used to prevent multiple simultaneous requests
  bool _isLoadingMore = false;

  // ==========================================================================
  // CONSTRUCTOR
  // ==========================================================================

  /// Creates a ProductNotifier
  ///
  /// INITIAL STATE: AsyncValue.data([])
  /// Empty list (no products loaded yet)
  ///
  /// NOTE: We don't auto-load products here.
  /// The UI should call loadProducts() explicitly.
  ProductNotifier(this._productService) : super(const AsyncValue.data([])) {
    // Auto-load initial products
    // This happens as soon as the provider is created
    loadProducts();
  }

  // ==========================================================================
  // GETTERS
  // ==========================================================================

  /// Check if there are more products to load
  ///
  /// LOGIC:
  /// If we haven't loaded all products yet, there are more to load
  ///
  /// EXAMPLE:
  /// - Loaded 10 of 50 products → hasMore = true
  /// - Loaded 50 of 50 products → hasMore = false
  bool get hasMore {
    // Get current product list
    final products = state.value ?? [];

    // Compare with total available
    return products.length < _total;
  }

  /// Check if currently loading more products
  bool get isLoadingMore => _isLoadingMore;

  // ==========================================================================
  // LOAD PRODUCTS
  // ==========================================================================

  /// Loads the first page of products
  ///
  /// WHEN TO CALL:
  /// - Initial load (screen opens)
  /// - Pull to refresh
  /// - Retry after error
  ///
  /// WHAT IT DOES:
  /// 1. Sets state to loading
  /// 2. Resets pagination (skip = 0)
  /// 3. Fetches first page of products
  /// 4. Updates state with products or error
  ///
  /// STATE CHANGES:
  /// ```
  /// Before: AsyncValue.data([...])        // Previous products or empty
  /// During: AsyncValue.loading()          // Loading new products
  /// Success: AsyncValue.data([...])       // New products loaded
  /// Error: AsyncValue.error(error, stack) // Failed to load
  /// ```
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// // Pull to refresh
  /// onRefresh: () async {
  ///   await ref.read(productListProvider.notifier).loadProducts();
  /// }
  /// ```
  Future<void> loadProducts() async {
    // Set state to loading
    // This shows loading indicator in UI
    state = const AsyncValue.loading();

    // Reset pagination
    _skip = 0;

    try {
      // Fetch first page of products
      final response = await _productService.getAllProducts(
        limit: _limit,
        skip: _skip,
      );

      // Update total count
      _total = response.total;

      // Update skip for next page
      _skip = response.products.length;

      // Set state to success with products
      state = AsyncValue.data(response.products);
    } catch (error, stackTrace) {
      // Set state to error
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // ==========================================================================
  // LOAD MORE PRODUCTS (PAGINATION)
  // ==========================================================================

  /// Loads the next page of products
  ///
  /// WHEN TO CALL:
  /// - User scrolls to bottom of list
  /// - User clicks "Load More" button
  ///
  /// WHAT IT DOES:
  /// 1. Checks if already loading or no more products
  /// 2. Sets loading flag
  /// 3. Fetches next page of products
  /// 4. Appends new products to existing list
  /// 5. Updates state
  ///
  /// WHY NOT SET state TO LOADING?
  /// We're adding to existing data, not replacing it.
  /// We use _isLoadingMore flag instead to show a bottom loading indicator.
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// // In ListView.builder
  /// ListView.builder(
  ///   itemCount: products.length + (hasMore ? 1 : 0),
  ///   itemBuilder: (context, index) {
  ///     if (index == products.length) {
  ///       // Reached end, load more
  ///       ref.read(productListProvider.notifier).loadMore();
  ///       return CircularProgressIndicator();
  ///     }
  ///     return ProductCard(product: products[index]);
  ///   },
  /// );
  /// ```
  Future<void> loadMore() async {
    // Check if we should load more
    if (_isLoadingMore || !hasMore) {
      // Already loading, or no more products to load
      return;
    }

    // Set loading flag
    _isLoadingMore = true;

    try {
      // Fetch next page of products
      final response = await _productService.getAllProducts(
        limit: _limit,
        skip: _skip,
      );

      // Get current products from state
      final currentProducts = state.value ?? [];

      // Append new products to existing list
      final updatedProducts = [...currentProducts, ...response.products];

      // Update skip for next page
      _skip = updatedProducts.length;

      // Update total (in case it changed)
      _total = response.total;

      // Update state with combined list
      state = AsyncValue.data(updatedProducts);
    } catch (error, stackTrace) {
      // Error loading more - keep current products, but log error
      // (We don't want to lose the products we already have!)
      print('Error loading more products: $error');

      // Optionally, you could show a snackbar or retry button here
    } finally {
      // Clear loading flag
      _isLoadingMore = false;
    }
  }

  // ==========================================================================
  // REFRESH
  // ==========================================================================

  /// Refreshes the product list
  ///
  /// WHEN TO CALL:
  /// - Pull to refresh gesture
  /// - After adding/removing products
  /// - Periodic refresh
  ///
  /// WHAT IT DOES:
  /// Same as loadProducts() but with clearer intent
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// RefreshIndicator(
  ///   onRefresh: () => ref.read(productListProvider.notifier).refresh(),
  ///   child: ProductList(),
  /// )
  /// ```
  Future<void> refresh() async {
    await loadProducts();
  }
}

// ============================================================================
// SINGLE PRODUCT PROVIDER
// ============================================================================

/// Provider for fetching a single product by ID
///
/// PROVIDER TYPE: FutureProvider.family<Product, int>
/// - FutureProvider: For async operations (returns Future)
/// - .family: Creates a provider for each unique parameter
/// - <Product, int>: Returns Product, takes int parameter (product ID)
///
/// WHY .family?
/// We need different providers for different product IDs:
/// - productProvider(1) for product with ID 1
/// - productProvider(2) for product with ID 2
/// - etc.
///
/// CACHING:
/// Riverpod caches the result for each product ID.
/// If you access productProvider(1) multiple times, it only fetches once.
///
/// AUTO-DISPOSE:
/// When no widgets are watching, the provider auto-disposes (frees memory)
///
/// EXAMPLE USAGE:
/// ```dart
/// // In ProductDetailsScreen
/// class ProductDetailsScreen extends ConsumerWidget {
///   final int productId;
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final productState = ref.watch(productProvider(productId));
///
///     return productState.when(
///       loading: () => LoadingScreen(),
///       data: (product) => ProductDetails(product: product),
///       error: (error, stack) => ErrorScreen(error: error),
///     );
///   }
/// }
/// ```
final productProvider =
    FutureProvider.family<Product, int>((ref, productId) async {
  // Get the product service
  final productService = ref.watch(productServiceProvider);

  // Fetch the product
  // This is called once per unique productId
  // The result is cached by Riverpod
  return await productService.getProductById(productId);
});

// ============================================================================
// CATEGORIES PROVIDER
// ============================================================================

/// Provider for product categories
///
/// PROVIDER TYPE: FutureProvider<List<String>>
/// - FutureProvider: For async operations
/// - Returns list of category names
///
/// CACHING:
/// Categories don't change often, so Riverpod caches them.
/// Only fetched once until provider is disposed or invalidated.
///
/// EXAMPLE USAGE:
/// ```dart
/// // In CategoryFilter widget
/// final categoriesState = ref.watch(categoriesProvider);
///
/// categoriesState.when(
///   loading: () => CircularProgressIndicator(),
///   data: (categories) => CategoryChips(categories: categories),
///   error: (error, stack) => Text('Failed to load categories'),
/// );
/// ```
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final productService = ref.watch(productServiceProvider);
  return await productService.getCategories();
});

// ============================================================================
// PRODUCTS BY CATEGORY PROVIDER
// ============================================================================

/// Provider for products in a specific category
///
/// PROVIDER TYPE: FutureProvider.family<ProductListResponse, String>
/// - Takes category name as parameter
/// - Returns ProductListResponse with products in that category
///
/// EXAMPLE USAGE:
/// ```dart
/// // When user selects "smartphones" category
/// final productsState = ref.watch(productsByCategoryProvider('smartphones'));
///
/// productsState.when(
///   loading: () => LoadingScreen(),
///   data: (response) => ProductGrid(products: response.products),
///   error: (error, stack) => ErrorScreen(error: error),
/// );
/// ```
final productsByCategoryProvider =
    FutureProvider.family<ProductListResponse, String>((ref, category) async {
  final productService = ref.watch(productServiceProvider);
  return await productService.getProductsByCategory(category);
});

// ============================================================================
// 📚 LEARNING NOTES
// ============================================================================
//
// KEY CONCEPTS:
//
// 1. PROVIDER TYPES:
//    - Provider: Sync, immutable value
//    - StateNotifierProvider: Async/sync, mutable state with logic
//    - FutureProvider: Async, auto-fetched on watch
//    - FutureProvider.family: Async, parameterized
//
// 2. PAGINATION STATE:
//    We track three things:
//    - Current products (in state)
//    - Skip offset (where to start next fetch)
//    - Total count (how many products exist)
//
//    Example progression:
//    ```
//    Load 1: skip=0,  limit=10 → Get products 1-10   (10 total)
//    Load 2: skip=10, limit=10 → Get products 11-20  (20 total)
//    Load 3: skip=20, limit=10 → Get products 21-30  (30 total)
//    ```
//
// 3. LOAD vs LOAD MORE:
//    - loadProducts(): Replaces entire list (pull to refresh)
//    - loadMore(): Appends to list (infinite scroll)
//
// 4. FUTURER vs STATE NOTIFIER PROVIDER:
//    - FutureProvider: Simple fetching (one-time load, auto-cached)
//    - StateNotifierProvider: Complex logic (multiple actions, manual control)
//
//    Use FutureProvider for:
//    - Single product details (fetched once)
//    - Categories (rarely changes)
//    - Simple fetches
//
//    Use StateNotifierProvider for:
//    - Product list (pagination, filtering, refresh)
//    - Shopping cart (add, remove, update)
//    - Complex state management
//
// 5. .family MODIFIER:
//    Creates a new provider for each unique parameter value
//
//    Example:
//    ```dart
//    ref.watch(productProvider(1))  // Provider for product 1
//    ref.watch(productProvider(2))  // Provider for product 2
//    ref.watch(productProvider(1))  // Reuses cached provider for product 1
//    ```
//
// 6. CACHING:
//    Riverpod caches provider results automatically:
//
//    ```dart
//    // First access: Fetches from API
//    final product1 = await ref.watch(productProvider(1));
//
//    // Second access: Returns cached result (no API call)
//    final product2 = await ref.watch(productProvider(1));
//    ```
//
//    To invalidate cache:
//    ```dart
//    ref.invalidate(productProvider(1));
//    ```
//
// 7. AUTO-DISPOSE:
//    When no widgets are watching, the provider disposes:
//
//    ```dart
//    // User navigates to product details
//    ref.watch(productProvider(1));  // Provider created, fetches product
//
//    // User navigates back
//    // No widgets watching anymore
//    // Provider auto-disposes after a short delay
//    ```
//
// ============================================================================
// 🎯 USAGE EXAMPLES
// ============================================================================
//
// DISPLAY PRODUCT LIST:
// ```dart
// class ProductListScreen extends ConsumerWidget {
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final productsState = ref.watch(productListProvider);
//
//     return productsState.when(
//       loading: () => Center(child: CircularProgressIndicator()),
//       data: (products) => ListView.builder(
//         itemCount: products.length,
//         itemBuilder: (context, index) => ProductCard(
//           product: products[index],
//         ),
//       ),
//       error: (error, stack) => ErrorWidget(error: error),
//     );
//   }
// }
// ```
//
// INFINITE SCROLL:
// ```dart
// class ProductListScreen extends ConsumerWidget {
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final productsState = ref.watch(productListProvider);
//     final notifier = ref.watch(productListProvider.notifier);
//
//     return productsState.when(
//       loading: () => LoadingScreen(),
//       data: (products) => ListView.builder(
//         itemCount: products.length + (notifier.hasMore ? 1 : 0),
//         itemBuilder: (context, index) {
//           if (index == products.length) {
//             // Reached end, load more
//             notifier.loadMore();
//             return LoadingIndicator();
//           }
//           return ProductCard(product: products[index]);
//         },
//       ),
//       error: (error, stack) => ErrorScreen(),
//     );
//   }
// }
// ```
//
// PULL TO REFRESH:
// ```dart
// RefreshIndicator(
//   onRefresh: () async {
//     await ref.read(productListProvider.notifier).refresh();
//   },
//   child: ProductList(),
// )
// ```
//
// PRODUCT DETAILS:
// ```dart
// class ProductDetailsScreen extends ConsumerWidget {
//   final int productId;
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final productState = ref.watch(productProvider(productId));
//
//     return productState.when(
//       loading: () => LoadingScreen(),
//       data: (product) => Column(
//         children: [
//           Image.network(product.thumbnail ?? ''),
//           Text(product.title),
//           Text('\$${product.price}'),
//         ],
//       ),
//       error: (error, stack) => ErrorScreen(),
//     );
//   }
// }
// ```
//
// ============================================================================
// 🎯 YOUR TASK
// ============================================================================
//
// Try implementing:
// 1. Category filter (show products from selected category)
// 2. Search functionality (use the search method you'll implement)
// 3. Sorting (by price, rating, etc.)
//
// ============================================================================
