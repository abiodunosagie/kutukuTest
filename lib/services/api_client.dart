// ============================================================================
// API CLIENT
// ============================================================================
// This is the CORE of your API integration! This class handles ALL HTTP
// requests to your backend.
//
// THINK OF IT AS:
// Your app's messenger that talks to the server. Every API call goes through
// this client.
//
// RESPONSIBILITIES:
// 1. Make HTTP requests (GET, POST, PUT, DELETE)
// 2. Add authentication headers
// 3. Handle responses
// 4. Handle errors
// 5. Parse JSON
// 6. Add timeout logic
//
// WHY CENTRALIZE API CALLS?
// Instead of making HTTP requests scattered throughout your app, you have
// ONE place that handles ALL network communication. This makes:
// - Debugging easier (check one file)
// - Token management automatic (headers added everywhere)
// - Error handling consistent (same logic everywhere)
// - Code reuse (write once, use everywhere)
// ============================================================================

import 'dart:convert'; // For JSON encoding/decoding
import 'dart:io'; // For HTTP exceptions and SocketException
import 'package:http/http.dart' as http; // HTTP client
import 'package:kutuku/utils/api_constants.dart'; // API endpoints
import 'package:kutuku/utils/storage_service.dart'; // Secure storage for tokens

// ============================================================================
// API CLIENT CLASS
// ============================================================================

/// Central HTTP client for making API requests
///
/// This class encapsulates all network communication logic.
/// All services (AuthService, ProductService, etc.) use this client.
///
/// DESIGN PATTERN: Dependency Injection
/// We inject StorageService so ApiClient can access auth tokens
class ApiClient {
  // ==========================================================================
  // PROPERTIES
  // ==========================================================================

  /// Base URL for all API requests
  /// Example: "https://dummyjson.com"
  ///
  /// WHY STORE THIS?
  /// Makes it easy to switch between dev/staging/production environments
  final String baseUrl;

  /// Storage service for accessing auth tokens
  /// We use this to get the token for authenticated requests
  ///
  /// WHY FINAL?
  /// Once set in constructor, we don't want to change it (prevents bugs)
  final StorageService _storageService;

  /// HTTP client instance
  /// We reuse the same client for all requests (better performance)
  ///
  /// WHY LATE?
  /// Initialized in constructor, but can't be in initializer list
  late final http.Client _client;

  // ==========================================================================
  // CONSTRUCTOR
  // ==========================================================================

  /// Creates an ApiClient instance
  ///
  /// PARAMETERS:
  /// - baseUrl: The root URL of the API
  /// - _storageService: Service for accessing secure storage
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// final storage = StorageService();
  /// final apiClient = ApiClient(ApiConstants.baseUrl, storage);
  /// ```
  ///
  /// NOTE: In real usage, Riverpod will create this for you!
  ApiClient(this.baseUrl, this._storageService) {
    // Initialize the HTTP client
    // We create one client and reuse it for all requests
    _client = http.Client();
  }

  // ==========================================================================
  // HELPER: BUILD HEADERS
  // ==========================================================================

  /// Builds headers for HTTP requests
  ///
  /// WHAT ARE HEADERS?
  /// Headers are metadata sent with requests. They tell the server:
  /// - What format you're sending (Content-Type: application/json)
  /// - Who you are (Authorization: Bearer token)
  /// - What format you want back (Accept: application/json)
  ///
  /// WHY ASYNC?
  /// We need to fetch the auth token from storage, which is async
  ///
  /// RETURNS:
  /// Map of header names to values
  ///
  /// EXAMPLE OUTPUT:
  /// ```dart
  /// {
  ///   'Content-Type': 'application/json',
  ///   'Accept': 'application/json',
  ///   'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
  /// }
  /// ```
  Future<Map<String, String>> _buildHeaders({bool includeAuth = true}) async {
    // Start with standard headers
    final headers = <String, String>{
      // Content-Type tells the server we're sending JSON
      'Content-Type': 'application/json',

      // Accept tells the server we want JSON back
      'Accept': 'application/json',
    };

    // Add authorization header if requested and token exists
    if (includeAuth) {
      // Get token from secure storage
      final token = await _storageService.getToken();

      // If token exists, add Authorization header
      if (token != null) {
        // Bearer is a standard auth scheme
        // Format: "Bearer <token>"
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ==========================================================================
  // HELPER: BUILD FULL URL
  // ==========================================================================

  /// Builds complete URL from endpoint
  ///
  /// COMBINES:
  /// Base URL + Endpoint
  ///
  /// EXAMPLE:
  /// ```dart
  /// _buildUrl('/auth/login')
  /// // Returns: "https://dummyjson.com/auth/login"
  /// ```
  String _buildUrl(String endpoint) {
    return baseUrl + endpoint;
  }

  // ==========================================================================
  // HELPER: HANDLE RESPONSE
  // ==========================================================================

  /// Processes HTTP response and handles errors
  ///
  /// WHAT THIS DOES:
  /// 1. Checks status code (200-299 = success, else = error)
  /// 2. Decodes JSON response
  /// 3. Throws appropriate exceptions for errors
  ///
  /// STATUS CODE RANGES:
  /// - 200-299: Success ✅
  /// - 400-499: Client error (your mistake) ❌
  /// - 500-599: Server error (their problem) 💥
  ///
  /// THROWS:
  /// HttpException with appropriate message for non-success status codes
  ///
  /// RETURNS:
  /// Decoded JSON as Map<String, dynamic>
  ///
  /// WHY Map<String, dynamic>?
  /// JSON objects become Dart Maps
  /// - String: The keys (field names)
  /// - dynamic: The values (can be any type: int, String, List, Map, etc.)
  Map<String, dynamic> _handleResponse(http.Response response) {
    // Log the request for debugging
    // In production, you might want to disable this or use a proper logger
    print('API Request: ${response.request?.method} ${response.request?.url}');
    print('Status Code: ${response.statusCode}');

    // Check if the status code indicates success
    // 200 = OK, 201 = Created, 204 = No Content, etc.
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // SUCCESS! ✅

      // If response body is empty, return empty map
      // Some APIs return empty body for DELETE requests
      if (response.body.isEmpty) {
        return {};
      }

      // Decode JSON string to Dart Map
      // Example: '{"id": 1, "name": "John"}' → {id: 1, name: "John"}
      try {
        return json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        // JSON decoding failed (invalid JSON from server)
        print('JSON Decode Error: $e');
        print('Response Body: ${response.body}');
        throw const HttpException('Invalid JSON response from server');
      }
    } else {
      // ERROR! ❌

      // Try to extract error message from response body
      String errorMessage = 'Request failed';

      try {
        // Many APIs return error details in JSON
        // Example: {"message": "Invalid credentials", "error": "INVALID_LOGIN"}
        final errorBody = json.decode(response.body);

        // Try to find an error message in common fields
        errorMessage = errorBody['message'] ??
            errorBody['error'] ??
            errorBody['detail'] ??
            'Request failed';
      } catch (e) {
        // If JSON parsing fails, use response body as error message
        errorMessage = response.body.isNotEmpty
            ? response.body
            : 'Request failed with status ${response.statusCode}';
      }

      // Log the error for debugging
      print('API Error: $errorMessage');

      // Throw an exception with the error message
      // The calling code can catch this and handle it appropriately
      throw HttpException(
        errorMessage,
        uri: response.request?.url,
      );
    }
  }

  // ==========================================================================
  // HTTP METHOD: GET
  // ==========================================================================

  /// Performs a GET request
  ///
  /// WHAT IS GET?
  /// GET requests retrieve data from the server.
  /// They don't modify anything - just fetch data.
  ///
  /// USE CASES:
  /// - Fetch list of products: GET /products
  /// - Fetch user profile: GET /users/1
  /// - Search products: GET /products/search?q=phone
  ///
  /// PARAMETERS:
  /// - endpoint: API path (e.g., '/products')
  /// - queryParams: Optional URL parameters (e.g., {'limit': '10', 'skip': '0'})
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// // Simple GET
  /// final data = await apiClient.get('/products');
  ///
  /// // GET with query parameters
  /// final data = await apiClient.get(
  ///   '/products',
  ///   queryParams: {'limit': '10', 'skip': '0'},
  /// );
  /// // Calls: GET /products?limit=10&skip=0
  /// ```
  ///
  /// THROWS:
  /// - HttpException: If request fails or returns error status
  /// - SocketException: If network is unavailable
  /// - TimeoutException: If request takes too long
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      // Build complete URL
      String url = _buildUrl(endpoint);

      // Add query parameters if provided
      if (queryParams != null && queryParams.isNotEmpty) {
        final uri = Uri.parse(url);
        url = uri.replace(queryParameters: queryParams).toString();
      }

      // Build headers (includes auth token if available)
      final headers = await _buildHeaders();

      // Make the request
      // Uri.parse converts string URL to Uri object
      // .timeout throws TimeoutException if request takes too long
      final response = await _client
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(
            ApiConstants.receiveTimeout,
            onTimeout: () {
              // This callback runs if request times out
              throw HttpException('Request timeout');
            },
          );

      // Process response and return data
      return _handleResponse(response);
    } on SocketException catch (e) {
      // Network error (no internet connection)
      print('Network Error: $e');
      throw HttpException('No internet connection');
    } on HttpException {
      // Re-throw HTTP exceptions as-is
      rethrow;
    } catch (e) {
      // Catch any other unexpected errors
      print('Unexpected Error: $e');
      throw HttpException('An unexpected error occurred: $e');
    }
  }

  // ==========================================================================
  // HTTP METHOD: POST
  // ==========================================================================

  /// Performs a POST request
  ///
  /// WHAT IS POST?
  /// POST requests send data to the server to create new resources
  /// or perform actions.
  ///
  /// USE CASES:
  /// - Login: POST /auth/login with {username, password}
  /// - Signup: POST /auth/register with {username, email, password}
  /// - Add to cart: POST /carts/add with {userId, productId, quantity}
  ///
  /// PARAMETERS:
  /// - endpoint: API path (e.g., '/auth/login')
  /// - body: Data to send (e.g., {'username': 'john', 'password': 'secret'})
  /// - includeAuth: Whether to include auth token in headers (default: true)
  ///
  /// WHY includeAuth PARAMETER?
  /// Some endpoints (like login) don't need auth because you're not logged in yet!
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// // Login (no auth token needed)
  /// final data = await apiClient.post(
  ///   '/auth/login',
  ///   body: {
  ///     'username': 'john',
  ///     'password': 'secret123',
  ///   },
  ///   includeAuth: false, // Not logged in yet!
  /// );
  ///
  /// // Add to cart (auth token required)
  /// final data = await apiClient.post(
  ///   '/carts/add',
  ///   body: {
  ///     'userId': 1,
  ///     'products': [{'id': 5, 'quantity': 1}],
  ///   },
  /// );
  /// ```
  ///
  /// THE BODY TRANSFORMATION:
  /// Your Dart Map → JSON String → Sent to Server
  /// Example:
  /// {'username': 'john'} → '{"username":"john"}' → HTTP Request Body
  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
    bool includeAuth = true,
  }) async {
    try {
      // Build complete URL
      final url = _buildUrl(endpoint);

      // Build headers
      final headers = await _buildHeaders(includeAuth: includeAuth);

      // Convert Dart Map to JSON String
      // Example: {username: 'john'} → '{"username":"john"}'
      final jsonBody = json.encode(body);

      // Log the request body for debugging
      print('Request Body: $jsonBody');

      // Make the request
      final response = await _client
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonBody, // Send JSON string
          )
          .timeout(
            ApiConstants.receiveTimeout,
            onTimeout: () {
              throw HttpException('Request timeout');
            },
          );

      // Process response and return data
      return _handleResponse(response);
    } on SocketException catch (e) {
      print('Network Error: $e');
      throw HttpException('No internet connection');
    } on HttpException {
      rethrow;
    } catch (e) {
      print('Unexpected Error: $e');
      throw HttpException('An unexpected error occurred: $e');
    }
  }

  // ==========================================================================
  // HTTP METHOD: PUT
  // ==========================================================================

  /// Performs a PUT request
  ///
  /// WHAT IS PUT?
  /// PUT requests update existing resources by replacing them entirely.
  ///
  /// USE CASES:
  /// - Update profile: PUT /users/1 with complete user data
  /// - Update product: PUT /products/5 with all product fields
  ///
  /// PUT vs PATCH:
  /// - PUT: Replace entire resource
  /// - PATCH: Update specific fields only
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// final data = await apiClient.put(
  ///   '/users/1',
  ///   body: {
  ///     'username': 'john_doe',
  ///     'email': 'john@example.com',
  ///     'firstName': 'John',
  ///     'lastName': 'Doe',
  ///   },
  /// );
  /// ```
  Future<Map<String, dynamic>> put(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _buildHeaders();
      final jsonBody = json.encode(body);

      print('Request Body: $jsonBody');

      final response = await _client
          .put(
            Uri.parse(url),
            headers: headers,
            body: jsonBody,
          )
          .timeout(
            ApiConstants.receiveTimeout,
            onTimeout: () {
              throw HttpException('Request timeout');
            },
          );

      return _handleResponse(response);
    } on SocketException catch (e) {
      print('Network Error: $e');
      throw HttpException('No internet connection');
    } on HttpException {
      rethrow;
    } catch (e) {
      print('Unexpected Error: $e');
      throw HttpException('An unexpected error occurred: $e');
    }
  }

  // ==========================================================================
  // HTTP METHOD: PATCH
  // ==========================================================================

  /// Performs a PATCH request
  ///
  /// WHAT IS PATCH?
  /// PATCH requests update specific fields of a resource without replacing it.
  ///
  /// USE CASES:
  /// - Update email only: PATCH /users/1 with {email: 'new@example.com'}
  /// - Update price only: PATCH /products/5 with {price: 999.99}
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// // Only update email, leave other fields unchanged
  /// final data = await apiClient.patch(
  ///   '/users/1',
  ///   body: {'email': 'newemail@example.com'},
  /// );
  /// ```
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _buildHeaders();
      final jsonBody = json.encode(body);

      print('Request Body: $jsonBody');

      final response = await _client
          .patch(
            Uri.parse(url),
            headers: headers,
            body: jsonBody,
          )
          .timeout(
            ApiConstants.receiveTimeout,
            onTimeout: () {
              throw HttpException('Request timeout');
            },
          );

      return _handleResponse(response);
    } on SocketException catch (e) {
      print('Network Error: $e');
      throw HttpException('No internet connection');
    } on HttpException {
      rethrow;
    } catch (e) {
      print('Unexpected Error: $e');
      throw HttpException('An unexpected error occurred: $e');
    }
  }

  // ==========================================================================
  // HTTP METHOD: DELETE
  // ==========================================================================

  /// Performs a DELETE request
  ///
  /// WHAT IS DELETE?
  /// DELETE requests remove resources from the server.
  ///
  /// USE CASES:
  /// - Delete account: DELETE /users/1
  /// - Remove from cart: DELETE /carts/1/products/5
  /// - Delete product: DELETE /products/5
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// // Delete a product
  /// await apiClient.delete('/products/5');
  ///
  /// // Delete a cart item
  /// await apiClient.delete('/carts/1');
  /// ```
  ///
  /// RETURNS:
  /// Usually empty map {} (most DELETE endpoints don't return data)
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final url = _buildUrl(endpoint);
      final headers = await _buildHeaders();

      final response = await _client
          .delete(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(
            ApiConstants.receiveTimeout,
            onTimeout: () {
              throw HttpException('Request timeout');
            },
          );

      return _handleResponse(response);
    } on SocketException catch (e) {
      print('Network Error: $e');
      throw HttpException('No internet connection');
    } on HttpException {
      rethrow;
    } catch (e) {
      print('Unexpected Error: $e');
      throw HttpException('An unexpected error occurred: $e');
    }
  }

  // ==========================================================================
  // CLEANUP
  // ==========================================================================

  /// Closes the HTTP client
  ///
  /// WHEN TO CALL THIS:
  /// When your app is closing or you're done with the API client
  ///
  /// WHY?
  /// Releases resources (sockets, memory)
  ///
  /// NOTE: In most cases, you won't need to call this manually.
  /// Riverpod handles lifecycle management for you.
  void dispose() {
    _client.close();
  }
}

// ============================================================================
// 📚 LEARNING NOTES
// ============================================================================
//
// KEY CONCEPTS:
//
// 1. HTTP CLIENT REUSE:
//    We create ONE http.Client and reuse it for all requests
//    WHY? Better performance - maintains connection pool
//
//    ❌ BAD (new client for each request):
//    Future<void> login() async {
//      final client = http.Client();
//      await client.post(...);
//      client.close();
//    }
//
//    ✅ GOOD (reuse same client):
//    class ApiClient {
//      final http.Client _client = http.Client();
//      Future<void> login() async {
//        await _client.post(...);
//      }
//    }
//
// 2. ASYNC/AWAIT:
//    All methods are async because network calls take time
//    await waits for the operation to complete before continuing
//
//    Example flow:
//    ```dart
//    print('1. Before request');
//    final data = await apiClient.get('/products'); // Waits here
//    print('2. After request');
//    print(data); // Only runs after request completes
//    ```
//
// 3. ERROR HANDLING:
//    We use try-catch to handle different error types:
//    - SocketException: No internet
//    - HttpException: API errors (401, 404, 500, etc.)
//    - TimeoutException: Request took too long
//    - Other: Unexpected errors
//
// 4. JSON ENCODING/DECODING:
//    JSON ↔ Dart conversion:
//
//    ENCODING (Dart → JSON):
//    ```dart
//    final map = {'username': 'john', 'age': 30};
//    final jsonString = json.encode(map);
//    // Result: '{"username":"john","age":30}'
//    ```
//
//    DECODING (JSON → Dart):
//    ```dart
//    final jsonString = '{"username":"john","age":30}';
//    final map = json.decode(jsonString);
//    // Result: {username: 'john', age: 30}
//    ```
//
// 5. HEADERS:
//    Headers provide metadata about the request:
//
//    Content-Type: 'application/json'
//    → "I'm sending JSON data"
//
//    Accept: 'application/json'
//    → "I want JSON back"
//
//    Authorization: 'Bearer token123'
//    → "I'm authenticated with this token"
//
// 6. STATUS CODES:
//    Every HTTP response has a status code:
//    - 2xx: Success (200 OK, 201 Created)
//    - 4xx: Client error (400 Bad Request, 401 Unauthorized, 404 Not Found)
//    - 5xx: Server error (500 Internal Server Error)
//
// 7. DEPENDENCY INJECTION:
//    We pass StorageService to ApiClient in the constructor
//    This makes testing easier and code more flexible
//
//    ```dart
//    // In production
//    final storage = StorageService();
//    final apiClient = ApiClient(ApiConstants.baseUrl, storage);
//
//    // In tests
//    final mockStorage = MockStorageService();
//    final apiClient = ApiClient('http://test.com', mockStorage);
//    ```
//
// ============================================================================
// 🎯 NEXT STEPS
// ============================================================================
//
// Now that you have ApiClient, you'll create services that use it:
// 1. AuthService - for login, signup, logout
// 2. ProductService - for fetching products
// 3. CartService - for cart operations
//
// These services will use ApiClient methods to make actual API calls!
//
// ============================================================================
