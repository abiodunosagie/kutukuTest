// ============================================================================
// PRODUCT SERVICE
// ============================================================================
// This service handles all product-related operations.
//
// RESPONSIBILITIES:
// 1. Fetch all products (with pagination)
// 2. Fetch single product by ID
// 3. Search products by keyword
// 4. Get product categories
// 5. Get products by category
//
// ARCHITECTURE:
// UI Layer → ProductService → ApiClient → Server
// ============================================================================

import 'package:kutuku/models/product.dart';
import 'package:kutuku/services/api_client.dart';
import 'package:kutuku/utils/api_constants.dart';

// ============================================================================
// PRODUCT SERVICE CLASS
// ============================================================================

/// Service for handling product-related operations
///
/// This class contains business logic for products.
/// It uses ApiClient to communicate with the server.
///
/// DESIGN PATTERN: Service Layer Pattern
class ProductService {
  // ==========================================================================
  // PROPERTIES
  // ==========================================================================

  /// API client for making HTTP requests
  final ApiClient _apiClient;

  // ==========================================================================
  // CONSTRUCTOR
  // ==========================================================================

  /// Creates a ProductService instance
  ///
  /// PARAMETERS:
  /// - _apiClient: The HTTP client for API calls
  ///
  /// EXAMPLE USAGE (via Riverpod):
  /// ```dart
  /// final productService = ref.watch(productServiceProvider);
  /// ```
  ProductService(this._apiClient);

  // ==========================================================================
  // GET ALL PRODUCTS
  // ==========================================================================

  /// Fetches a paginated list of products
  ///
  /// THE FLOW:
  /// ```
  /// 1. UI requests products (e.g., on home screen load)
  /// 2. UI calls productService.getAllProducts(limit: 10, skip: 0)
  /// 3. ProductService sends GET request to /products?limit=10&skip=0
  /// 4. Server returns paginated product list
  /// 5. ProductService converts JSON to ProductListResponse
  /// 6. ProductService returns ProductListResponse to UI
  /// 7. UI displays products
  /// ```
  ///
  /// API ENDPOINT:
  /// GET /products?limit={limit}&skip={skip}
  ///
  /// QUERY PARAMETERS:
  /// - limit: Number of products to return (default: 10)
  /// - skip: Number of products to skip for pagination (default: 0)
  ///
  /// RESPONSE (Success):
  /// ```json
  /// {
  ///   "products": [
  ///     {
  ///       "id": 1,
  ///       "title": "iPhone 15 Pro",
  ///       "description": "...",
  ///       "price": 1099.99,
  ///       "category": "smartphones",
  ///       "thumbnail": "https://...",
  ///       ...
  ///     },
  ///     ...
  ///   ],
  ///   "total": 194,
  ///   "skip": 0,
  ///   "limit": 10
  /// }
  /// ```
  ///
  /// PAGINATION EXAMPLES:
  /// - Page 1: limit=10, skip=0 (products 1-10)
  /// - Page 2: limit=10, skip=10 (products 11-20)
  /// - Page 3: limit=10, skip=20 (products 21-30)
  ///
  /// PARAMETERS:
  /// - limit: How many products to fetch (default: 10)
  /// - skip: How many products to skip (default: 0)
  ///
  /// RETURNS:
  /// ProductListResponse with products array and pagination info
  ///
  /// THROWS:
  /// - HttpException: If request fails
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// // Get first 10 products
  /// final response = await productService.getAllProducts();
  /// print('Loaded ${response.products.length} of ${response.total} products');
  ///
  /// // Get next 10 products (pagination)
  /// final nextPage = await productService.getAllProducts(skip: 10);
  ///
  /// // Get 20 products at once
  /// final more = await productService.getAllProducts(limit: 20);
  /// ```
  ///
  /// STEP-BY-STEP BREAKDOWN:
  Future<ProductListResponse> getAllProducts({
    int limit = ApiConstants.defaultLimit,
    int skip = ApiConstants.defaultSkip,
  }) async {
    // STEP 1: Make API call with query parameters
    // We use GET because we're just fetching data (not modifying anything)
    final response = await _apiClient.get(
      ApiConstants.products, // The endpoint: '/products'
      queryParams: {
        // Query parameters for pagination
        // These are added to the URL: /products?limit=10&skip=0
        'limit': limit.toString(), // Convert int to String
        'skip': skip.toString(), // Convert int to String
      },
    );

    // At this point, response is a Map<String, dynamic> like:
    // {
    //   products: [{id: 1, title: '...'}, ...],
    //   total: 194,
    //   skip: 0,
    //   limit: 10
    // }

    // STEP 2: Convert JSON response to ProductListResponse object
    // This uses the ProductListResponse.fromJson factory method
    // It automatically converts the products array to List<Product>
    final productListResponse = ProductListResponse.fromJson(response);

    // Log for debugging
    print('Fetched ${productListResponse.products.length} products');

    // STEP 3: Return the ProductListResponse
    // This contains:
    // - products: List<Product>
    // - total: Total number of products available
    // - skip: Current offset
    // - limit: Current page size
    return productListResponse;
  }

  // ==========================================================================
  // GET SINGLE PRODUCT
  // ==========================================================================

  /// Fetches a single product by ID
  ///
  /// THE FLOW:
  /// ```
  /// 1. User taps on a product card
  /// 2. UI navigates to product details screen
  /// 3. UI calls productService.getProductById(productId)
  /// 4. ProductService sends GET request to /products/{id}
  /// 5. Server returns full product details
  /// 6. ProductService converts JSON to Product
  /// 7. ProductService returns Product to UI
  /// 8. UI displays product details
  /// ```
  ///
  /// API ENDPOINT:
  /// GET /products/{id}
  ///
  /// EXAMPLE REQUEST:
  /// GET /products/1
  ///
  /// RESPONSE (Success):
  /// ```json
  /// {
  ///   "id": 1,
  ///   "title": "iPhone 15 Pro",
  ///   "description": "Latest iPhone with A17 Pro chip...",
  ///   "price": 1099.99,
  ///   "discountPercentage": 10.5,
  ///   "rating": 4.5,
  ///   "stock": 50,
  ///   "brand": "Apple",
  ///   "category": "smartphones",
  ///   "thumbnail": "https://...",
  ///   "images": ["https://...", "https://...", ...],
  ///   "reviews": [...],
  ///   ...
  /// }
  /// ```
  ///
  /// WHEN TO USE:
  /// - Viewing product details
  /// - Refreshing product data
  /// - Checking latest stock/price
  ///
  /// PARAMETERS:
  /// - productId: The ID of the product to fetch
  ///
  /// RETURNS:
  /// Product object with all product details
  ///
  /// THROWS:
  /// - HttpException: If product not found or request fails
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// try {
  ///   final product = await productService.getProductById(1);
  ///   print('Product: ${product.title}');
  ///   print('Price: \$${product.price}');
  ///   print('In stock: ${product.stock}');
  /// } catch (e) {
  ///   print('Product not found: $e');
  /// }
  /// ```
  ///
  /// STEP-BY-STEP BREAKDOWN:
  Future<Product> getProductById(int productId) async {
    // STEP 1: Build the endpoint with product ID
    // Example: '/products' + '/1' = '/products/1'
    final endpoint = '${ApiConstants.productById}/$productId';

    // STEP 2: Make API call
    // We use GET because we're just fetching data
    final response = await _apiClient.get(endpoint);

    // At this point, response is a Map<String, dynamic> with product data
    // Example: {id: 1, title: 'iPhone 15 Pro', price: 1099.99, ...}

    // STEP 3: Convert JSON response to Product object
    final product = Product.fromJson(response);

    // Log for debugging
    print('Fetched product: ${product.title}');

    // STEP 4: Return the Product
    return product;
  }

  // ==========================================================================
  // SEARCH PRODUCTS
  // ==========================================================================

  /// Searches products by keyword
  ///
  /// THE FLOW:
  /// ```
  /// 1. User types in search bar (e.g., "phone")
  /// 2. UI calls productService.searchProducts("phone")
  /// 3. ProductService sends GET request to /products/search?q=phone
  /// 4. Server returns matching products
  /// 5. ProductService converts JSON to ProductListResponse
  /// 6. ProductService returns ProductListResponse to UI
  /// 7. UI displays search results
  /// ```
  ///
  /// API ENDPOINT:
  /// GET /products/search?q={query}
  ///
  /// QUERY PARAMETERS:
  /// - q: Search keyword
  /// - limit: Number of results to return (optional)
  /// - skip: Pagination offset (optional)
  ///
  /// EXAMPLE REQUEST:
  /// GET /products/search?q=phone&limit=10&skip=0
  ///
  /// RESPONSE (Success):
  /// ```json
  /// {
  ///   "products": [
  ///     {
  ///       "id": 1,
  ///       "title": "iPhone 15 Pro",
  ///       ...
  ///     },
  ///     {
  ///       "id": 5,
  ///       "title": "Samsung Galaxy S24",
  ///       ...
  ///     }
  ///   ],
  ///   "total": 5,
  ///   "skip": 0,
  ///   "limit": 10
  /// }
  /// ```
  ///
  /// SEARCH BEHAVIOR:
  /// The API searches in:
  /// - Product title
  /// - Product description
  /// - Product brand
  ///
  /// WHEN TO USE:
  /// - User searches for products
  /// - Auto-complete suggestions
  /// - Filtering products
  ///
  /// PARAMETERS:
  /// - query: The search keyword
  /// - limit: Maximum results to return (default: 10)
  /// - skip: Pagination offset (default: 0)
  ///
  /// RETURNS:
  /// ProductListResponse with matching products
  ///
  /// THROWS:
  /// - HttpException: If request fails
  ///
  /// 🎯 YOUR TASK:
  /// Implement this method following the pattern from getAllProducts!
  ///
  /// HINTS:
  /// 1. Use _apiClient.get()
  /// 2. Endpoint: ApiConstants.productSearch
  /// 3. Query parameters: 'q' (query), 'limit', 'skip'
  /// 4. Convert response to ProductListResponse.fromJson()
  /// 5. Return ProductListResponse
  ///
  /// EXAMPLE IMPLEMENTATION:
  /// ```dart
  /// Future<ProductListResponse> searchProducts(
  ///   String query, {
  ///   int limit = ApiConstants.defaultLimit,
  ///   int skip = ApiConstants.defaultSkip,
  /// }) async {
  ///   // TODO: Make API call with query parameters
  ///   // TODO: Convert response to ProductListResponse
  ///   // TODO: Return result
  /// }
  /// ```
  ///
  /// TEST WITH:
  /// ```dart
  /// final results = await productService.searchProducts('phone');
  /// print('Found ${results.total} products matching "phone"');
  /// ```
  Future<ProductListResponse> searchProducts(
    String query, {
    int limit = ApiConstants.defaultLimit,
    int skip = ApiConstants.defaultSkip,
  }) async {
    // 🎯 YOUR IMPLEMENTATION HERE!
    // Follow the same pattern as getAllProducts, but add 'q' query parameter

    throw UnimplementedError(
      'Search products method not implemented yet!\n'
      'This is YOUR task to complete.\n'
      'Follow the pattern from getAllProducts method above.\n'
      'Hint: Add query parameter "q" with the search term.\n'
      'Check the comments for more hints!',
    );
  }

  // ==========================================================================
  // GET CATEGORIES
  // ==========================================================================

  /// Fetches all available product categories
  ///
  /// THE FLOW:
  /// ```
  /// 1. UI needs category list (e.g., for category filter)
  /// 2. UI calls productService.getCategories()
  /// 3. ProductService sends GET request to /products/categories
  /// 4. Server returns list of category names
  /// 5. ProductService returns list to UI
  /// 6. UI displays categories
  /// ```
  ///
  /// API ENDPOINT:
  /// GET /products/categories
  ///
  /// RESPONSE (Success):
  /// ```json
  /// [
  ///   "smartphones",
  ///   "laptops",
  ///   "fragrances",
  ///   "skincare",
  ///   "groceries",
  ///   "home-decoration",
  ///   ...
  /// ]
  /// ```
  ///
  /// WHEN TO USE:
  /// - Displaying category filter
  /// - Category navigation menu
  /// - Category chips/tags
  ///
  /// RETURNS:
  /// List of category names (List<String>)
  ///
  /// THROWS:
  /// - HttpException: If request fails
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// final categories = await productService.getCategories();
  /// print('Available categories: $categories');
  ///
  /// // Display in UI
  /// for (var category in categories) {
  ///   print('- $category');
  /// }
  /// ```
  ///
  /// STEP-BY-STEP BREAKDOWN:
  Future<List<String>> getCategories() async {
    // STEP 1: Make API call
    final response = await _apiClient.get(ApiConstants.categories);

    // STEP 2: Handle response
    // The API returns an array directly, not an object
    // So response might be a List, not a Map
    //
    // API response structure:
    // ["smartphones", "laptops", "fragrances", ...]

    List<String> categories;

    if (response is List) {
      // Response is already a list
      categories = response.cast<String>();
    } else if (response is Map && response.containsKey('categories')) {
      // Response is an object with 'categories' key
      categories = (response['categories'] as List).cast<String>();
    } else {
      // Unexpected response format
      print('Unexpected response format: $response');
      categories = [];
    }

    // Log for debugging
    print('Fetched ${categories.length} categories');

    // STEP 3: Return the list
    return categories;
  }

  // ==========================================================================
  // GET PRODUCTS BY CATEGORY
  // ==========================================================================

  /// Fetches products in a specific category
  ///
  /// THE FLOW:
  /// ```
  /// 1. User selects a category (e.g., "smartphones")
  /// 2. UI calls productService.getProductsByCategory("smartphones")
  /// 3. ProductService sends GET request to /products/category/smartphones
  /// 4. Server returns products in that category
  /// 5. ProductService converts JSON to ProductListResponse
  /// 6. ProductService returns ProductListResponse to UI
  /// 7. UI displays filtered products
  /// ```
  ///
  /// API ENDPOINT:
  /// GET /products/category/{category}
  ///
  /// EXAMPLE REQUEST:
  /// GET /products/category/smartphones
  ///
  /// RESPONSE (Success):
  /// ```json
  /// {
  ///   "products": [
  ///     {
  ///       "id": 1,
  ///       "title": "iPhone 15 Pro",
  ///       "category": "smartphones",
  ///       ...
  ///     },
  ///     ...
  ///   ],
  ///   "total": 5,
  ///   "skip": 0,
  ///   "limit": 10
  /// }
  /// ```
  ///
  /// WHEN TO USE:
  /// - Category filter in home screen
  /// - Category-specific pages
  /// - Browsing by category
  ///
  /// PARAMETERS:
  /// - category: The category name (e.g., "smartphones", "laptops")
  ///
  /// RETURNS:
  /// ProductListResponse with products in that category
  ///
  /// THROWS:
  /// - HttpException: If category doesn't exist or request fails
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// final response = await productService.getProductsByCategory('smartphones');
  /// print('Found ${response.products.length} smartphones');
  ///
  /// for (var product in response.products) {
  ///   print('- ${product.title}: \$${product.price}');
  /// }
  /// ```
  ///
  /// STEP-BY-STEP BREAKDOWN:
  Future<ProductListResponse> getProductsByCategory(String category) async {
    // STEP 1: Build the endpoint with category
    // Example: '/products/category' + '/smartphones' = '/products/category/smartphones'
    final endpoint = '${ApiConstants.productsByCategory}/$category';

    // STEP 2: Make API call
    final response = await _apiClient.get(endpoint);

    // At this point, response is a Map with products in the category

    // STEP 3: Convert JSON response to ProductListResponse
    final productListResponse = ProductListResponse.fromJson(response);

    // Log for debugging
    print(
        'Fetched ${productListResponse.products.length} products in category: $category');

    // STEP 4: Return the result
    return productListResponse;
  }
}

// ============================================================================
// 📚 LEARNING NOTES
// ============================================================================
//
// KEY CONCEPTS:
//
// 1. PAGINATION:
//    Loading data in chunks instead of all at once
//
//    WHY?
//    - Faster initial load (don't wait for 194 products)
//    - Less memory usage (don't store all products)
//    - Better UX (show data quickly, load more as needed)
//
//    HOW IT WORKS:
//    ```dart
//    // Page 1: Load first 10 products
//    final page1 = await getAllProducts(limit: 10, skip: 0);
//
//    // Page 2: Load next 10 products
//    final page2 = await getAllProducts(limit: 10, skip: 10);
//
//    // Page 3: Load next 10 products
//    final page3 = await getAllProducts(limit: 10, skip: 20);
//    ```
//
//    FORMULA:
//    skip = (pageNumber - 1) * limit
//
//    Example for page 5 with 10 items per page:
//    skip = (5 - 1) * 10 = 40
//
// 2. QUERY PARAMETERS:
//    Data sent in the URL after '?'
//
//    FORMAT:
//    /products?limit=10&skip=0&sort=price
//    - First parameter: ?key=value
//    - Additional parameters: &key=value
//
//    IN DART:
//    ```dart
//    final response = await _apiClient.get(
//      '/products',
//      queryParams: {
//        'limit': '10',
//        'skip': '0',
//        'sort': 'price',
//      },
//    );
//    // Becomes: /products?limit=10&skip=0&sort=price
//    ```
//
// 3. PATH PARAMETERS:
//    Data sent as part of the URL path
//
//    FORMAT:
//    /products/{id} → /products/1
//    /products/category/{category} → /products/category/smartphones
//
//    IN DART:
//    ```dart
//    final productId = 1;
//    final endpoint = '/products/$productId';
//    // Result: /products/1
//    ```
//
// 4. RESPONSE STRUCTURES:
//    Different endpoints return different structures:
//
//    OBJECT RESPONSE:
//    ```json
//    {"id": 1, "title": "iPhone", ...}
//    ```
//    Convert with: Product.fromJson(response)
//
//    ARRAY RESPONSE:
//    ```json
//    ["smartphones", "laptops", ...]
//    ```
//    Cast with: (response as List).cast<String>()
//
//    PAGINATED RESPONSE:
//    ```json
//    {
//      "products": [...],
//      "total": 194,
//      "skip": 0,
//      "limit": 10
//    }
//    ```
//    Convert with: ProductListResponse.fromJson(response)
//
// 5. ERROR HANDLING:
//    Always wrap service calls in try-catch:
//
//    ```dart
//    try {
//      final products = await productService.getAllProducts();
//      // Success - display products
//    } on HttpException catch (e) {
//      // API error - show error message
//      showError(e.message);
//    } catch (e) {
//      // Unexpected error
//      showError('An error occurred');
//    }
//    ```
//
// 6. SERVICE PATTERNS:
//    All service methods follow the same pattern:
//
//    ```dart
//    Future<ReturnType> methodName(parameters) async {
//      // 1. Build endpoint (if needed)
//      final endpoint = '/path/$parameter';
//
//      // 2. Make API call
//      final response = await _apiClient.get/post/put/delete(endpoint);
//
//      // 3. Convert response to model
//      final model = Model.fromJson(response);
//
//      // 4. Return model
//      return model;
//    }
//    ```
//
// 7. CASTING:
//    Converting types in Dart:
//
//    ```dart
//    // Cast List<dynamic> to List<String>
//    final dynamic list = ['a', 'b', 'c'];
//    final stringList = (list as List).cast<String>();
//
//    // Cast Map<String, dynamic> values
//    final map = {'count': 5};
//    final count = map['count'] as int;
//
//    // Safe casting with null check
//    final nullableCount = map['count'] as int?;
//    ```
//
// ============================================================================
// 🎯 INFINITE SCROLL EXAMPLE
// ============================================================================
//
// Implementing infinite scroll with pagination:
//
// ```dart
// class ProductListScreen extends StatefulWidget {
//   @override
//   _ProductListScreenState createState() => _ProductListScreenState();
// }
//
// class _ProductListScreenState extends State<ProductListScreen> {
//   final List<Product> _products = [];
//   int _skip = 0;
//   final int _limit = 10;
//   bool _isLoading = false;
//   bool _hasMore = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadProducts();
//   }
//
//   Future<void> _loadProducts() async {
//     if (_isLoading || !_hasMore) return;
//
//     setState(() => _isLoading = true);
//
//     try {
//       final response = await productService.getAllProducts(
//         limit: _limit,
//         skip: _skip,
//       );
//
//       setState(() {
//         _products.addAll(response.products);
//         _skip += _limit;
//         _hasMore = _products.length < response.total;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       // Show error
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       itemCount: _products.length + (_hasMore ? 1 : 0),
//       itemBuilder: (context, index) {
//         if (index == _products.length) {
//           _loadProducts(); // Load more when reaching end
//           return CircularProgressIndicator();
//         }
//         return ProductCard(product: _products[index]);
//       },
//     );
//   }
// }
// ```
//
// ============================================================================
// 🎯 YOUR TASK
// ============================================================================
//
// IMPLEMENT THE SEARCH METHOD!
//
// Follow the same pattern as getAllProducts:
// 1. Make API call with _apiClient.get()
// 2. Use ApiConstants.productSearch endpoint
// 3. Add query parameters: 'q' (the search term), 'limit', 'skip'
// 4. Convert response to ProductListResponse.fromJson()
// 5. Return the result
//
// TIP: Look at getAllProducts and replicate its structure, just add the 'q' parameter!
//
// ============================================================================
