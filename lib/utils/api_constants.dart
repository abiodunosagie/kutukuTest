// ============================================================================
// API CONSTANTS
// ============================================================================
// This file centralizes all API endpoints and configuration.
//
// WHY THIS FILE EXISTS:
// Instead of hardcoding URLs throughout your app, you define them once here.
// If the API changes (e.g., from dummyjson.com to your real backend), you
// only need to update this file!
//
// ORGANIZATION:
// - Base URL: The root domain of the API
// - Endpoint paths: Specific routes for different resources
// ============================================================================

class ApiConstants {
  // ============================================================================
  // BASE URL
  // ============================================================================
  // The root URL of the API. All endpoints will be appended to this.
  // Example: baseUrl + login = "https://dummyjson.com/auth/login"
  static const String baseUrl = 'https://dummyjson.com';

  // ============================================================================
  // AUTHENTICATION ENDPOINTS
  // ============================================================================
  // These endpoints handle user authentication (login, signup, etc.)

  // LOGIN ENDPOINT
  // Purpose: Authenticate user and get access token
  // Method: POST
  // Body: { "username": "...", "password": "..." }
  // Response: { "id": 1, "username": "...", "token": "...", ... }
  static const String login = '/auth/login';

  // REGISTER ENDPOINT
  // Purpose: Create a new user account
  // Method: POST
  // Body: { "username": "...", "email": "...", "password": "..." }
  // Response: { "id": 1, "username": "...", "email": "..." }
  //
  // 🎯 YOUR TASK: You'll use this in the signup screen!
  static const String register = '/users/add';

  // GET CURRENT USER ENDPOINT
  // Purpose: Fetch the currently authenticated user's profile
  // Method: GET
  // Headers: Authorization: Bearer {token}
  // Response: { "id": 1, "username": "...", "email": "...", ... }
  static const String me = '/auth/me';

  // ============================================================================
  // PRODUCT ENDPOINTS
  // ============================================================================
  // These endpoints handle product-related operations

  // GET ALL PRODUCTS ENDPOINT
  // Purpose: Fetch a paginated list of products
  // Method: GET
  // Query params: ?limit=10&skip=0
  // Response: { "products": [...], "total": 100, "skip": 0, "limit": 10 }
  static const String products = '/products';

  // GET SINGLE PRODUCT ENDPOINT
  // Purpose: Fetch details of a specific product
  // Method: GET
  // Usage: ApiConstants.products + '/$productId'
  // Example: /products/1
  // Response: { "id": 1, "title": "iPhone", "price": 549, ... }
  static const String productById = '/products'; // Append /{id}

  // SEARCH PRODUCTS ENDPOINT
  // Purpose: Search products by keyword
  // Method: GET
  // Usage: ApiConstants.productSearch + '?q=phone'
  // Example: /products/search?q=phone
  // Response: { "products": [...], "total": 5, ... }
  //
  // 🎯 YOUR TASK: You'll implement search functionality with this!
  static const String productSearch = '/products/search';

  // GET PRODUCT CATEGORIES ENDPOINT
  // Purpose: Fetch all available product categories
  // Method: GET
  // Response: ["smartphones", "laptops", "fragrances", ...]
  static const String categories = '/products/categories';

  // GET PRODUCTS BY CATEGORY ENDPOINT
  // Purpose: Fetch products in a specific category
  // Method: GET
  // Usage: ApiConstants.productsByCategory + '/smartphones'
  // Response: { "products": [...], "total": 5 }
  static const String productsByCategory = '/products/category';

  // ============================================================================
  // CART ENDPOINTS
  // ============================================================================
  // These endpoints handle shopping cart operations

  // GET USER CART ENDPOINT
  // Purpose: Fetch the current user's shopping cart
  // Method: GET
  // Usage: ApiConstants.carts + '/user/$userId'
  // Response: { "carts": [...], "total": 1 }
  //
  // 🎯 YOUR TASK: You'll implement cart functionality with this!
  static const String carts = '/carts';

  // ADD TO CART ENDPOINT
  // Purpose: Add a product to the user's cart
  // Method: POST
  // Body: { "userId": 1, "products": [{"id": 1, "quantity": 1}] }
  // Response: { "id": 1, "products": [...], "total": 549 }
  static const String addToCart = '/carts/add';

  // ============================================================================
  // PAGINATION DEFAULTS
  // ============================================================================
  // Default values for pagination parameters

  // Default number of items per page
  static const int defaultLimit = 10;

  // Default starting position (used for pagination)
  static const int defaultSkip = 0;

  // ============================================================================
  // TIMEOUT CONFIGURATION
  // ============================================================================
  // How long to wait for API responses before giving up

  // Connection timeout: Time to establish connection with server
  static const Duration connectTimeout = Duration(seconds: 30);

  // Receive timeout: Time to wait for response after connection is made
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ============================================================================
  // HELPER METHOD: Build URL with Query Parameters
  // ============================================================================
  // This method helps you construct URLs with query parameters easily.
  //
  // WHAT ARE QUERY PARAMETERS?
  // They're key-value pairs added to the end of a URL after a "?"
  // Example: /products?limit=10&skip=0
  //
  // WHY USE THIS METHOD?
  // Instead of manually concatenating strings like:
  // "$baseUrl$products?limit=10&skip=0"
  // You can use:
  // buildUrl(products, {'limit': '10', 'skip': '0'})
  //
  // PARAMETERS:
  // - endpoint: The API path (e.g., '/products')
  // - queryParams: A map of parameter names and values
  //
  // RETURNS:
  // Complete URL string with query parameters
  //
  // EXAMPLE USAGE:
  // String url = ApiConstants.buildUrl(
  //   ApiConstants.products,
  //   {'limit': '10', 'skip': '0'}
  // );
  // Result: "https://dummyjson.com/products?limit=10&skip=0"
  static String buildUrl(String endpoint, [Map<String, String>? queryParams]) {
    // Start with base URL + endpoint
    String url = baseUrl + endpoint;

    // If there are query parameters, add them
    if (queryParams != null && queryParams.isNotEmpty) {
      // Uri.http/https automatically formats query parameters correctly
      final uri = Uri.parse(url);

      // Create a new URI with the query parameters
      final newUri = uri.replace(queryParameters: queryParams);

      return newUri.toString();
    }

    // If no query parameters, return the base URL
    return url;
  }

  // ============================================================================
  // HELPER METHOD: Build Full URL
  // ============================================================================
  // Simple helper to construct complete URLs
  //
  // EXAMPLE USAGE:
  // String url = ApiConstants.fullUrl('/products/1');
  // Result: "https://dummyjson.com/products/1"
  static String fullUrl(String endpoint) {
    return baseUrl + endpoint;
  }
}

// ============================================================================
// 📚 LEARNING NOTES
// ============================================================================
//
// KEY CONCEPTS:
//
// 1. CONSTANTS vs VARIABLES:
//    - const: Value is fixed at compile time (never changes)
//    - final: Value is set once at runtime (can't be reassigned)
//    - var/String: Value can be changed anytime
//
//    We use 'const' because API endpoints don't change during runtime.
//
// 2. STATIC vs INSTANCE:
//    - static: Belongs to the class itself (ApiConstants.login)
//    - instance: Belongs to an object (apiConstants.login)
//
//    We use 'static' so you don't need to create an instance:
//    ✅ ApiConstants.login
//    ❌ ApiConstants().login
//
// 3. STRING INTERPOLATION:
//    You can combine strings in Dart using:
//    - Concatenation: 'hello' + 'world'
//    - Interpolation: '$baseUrl$login' or '${expression}'
//
// 4. QUERY PARAMETERS:
//    Format: ?key1=value1&key2=value2
//    Example: /products?limit=10&skip=0
//    - First parameter uses '?'
//    - Additional parameters use '&'
//    - Spaces are encoded as '%20'
//
// 5. WHY CENTRALIZE CONSTANTS?
//    ✅ Change once, apply everywhere
//    ✅ Avoid typos (autocomplete works!)
//    ✅ Easy to switch between dev/staging/production
//    ✅ Better code organization
//
// ============================================================================
// 🎯 NEXT STEPS
// ============================================================================
//
// Now that you have API endpoints defined, you'll:
// 1. Create models to represent the data
// 2. Create services to call these endpoints
// 3. Create providers to manage state
// 4. Use providers in your UI
//
// ============================================================================
