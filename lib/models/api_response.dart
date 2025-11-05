// ============================================================================
// API RESPONSE MODEL
// ============================================================================
// This file defines a generic wrapper for API responses.
//
// WHY DO WE NEED THIS?
// APIs can return success OR error responses. We need a consistent way to
// handle both cases throughout our app.
//
// WHAT DOES IT SOLVE?
// 1. Consistent error handling
// 2. Type-safe response parsing
// 3. Clear success/failure states
// 4. Standardized error messages
//
// Instead of checking status codes everywhere, we check response.success
// ============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

// ============================================================================
// API RESPONSE CLASS
// ============================================================================

/// Generic wrapper for API responses
///
/// GENERIC TYPE PARAMETER <T>:
/// T represents the type of data this response contains
/// Example: ApiResponse<User>, ApiResponse<Product>, ApiResponse<List<Product>>
///
/// WHY GENERICS?
/// Instead of creating ApiResponse<User>, ApiResponse<Product>, etc.,
/// we create ONE ApiResponse<T> that works with any type!
///
/// EXAMPLE RESPONSES:
///
/// SUCCESS:
/// ```json
/// {
///   "success": true,
///   "message": "Login successful",
///   "data": { "id": 1, "username": "john", ... }
/// }
/// ```
///
/// ERROR:
/// ```json
/// {
///   "success": false,
///   "message": "Invalid credentials",
///   "error": "Authentication failed"
/// }
/// ```
@freezed
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    /// Indicates if the request was successful
    /// true = success, false = error
    ///
    /// USAGE:
    /// ```dart
    /// if (response.success) {
    ///   // Handle success
    ///   print(response.data);
    /// } else {
    ///   // Handle error
    ///   print(response.message);
    /// }
    /// ```
    @Default(true) bool success,

    /// Human-readable message
    /// Success: "Login successful", "Product added to cart"
    /// Error: "Invalid credentials", "Product out of stock"
    String? message,

    /// The actual data returned by the API
    /// Can be any type: User, Product, List<Product>, etc.
    ///
    /// WHY NULLABLE?
    /// - Success responses have data
    /// - Error responses might not have data
    ///
    /// EXAMPLE:
    /// ```dart
    /// final response = ApiResponse<User>(data: user);
    /// final user = response.data; // Type: User?
    /// ```
    T? data,

    /// Error details (if request failed)
    /// Only present when success = false
    ///
    /// Could be:
    /// - Error message from server
    /// - Exception message
    /// - Validation errors
    ///
    /// EXAMPLE:
    /// ```dart
    /// ApiResponse(
    ///   success: false,
    ///   message: 'Validation failed',
    ///   error: 'Email is required',
    /// )
    /// ```
    String? error,

    /// HTTP status code (optional)
    /// 200 = OK, 404 = Not Found, 500 = Server Error, etc.
    ///
    /// USEFUL FOR:
    /// - Detailed error handling
    /// - Debugging
    /// - Analytics
    ///
    /// EXAMPLE:
    /// ```dart
    /// if (response.statusCode == 401) {
    ///   // Unauthorized - redirect to login
    /// }
    /// ```
    int? statusCode,
  }) = _ApiResponse<T>;

  /// Creates ApiResponse from JSON
  ///
  /// PROBLEM WITH GENERICS:
  /// Freezed can't automatically deserialize the generic type T
  /// We need to tell it HOW to deserialize T
  ///
  /// SOLUTION:
  /// Pass a fromJsonT function that knows how to deserialize T
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// // For User response
  /// final response = ApiResponse<User>.fromJson(
  ///   json,
  ///   (data) => User.fromJson(data as Map<String, dynamic>),
  /// );
  ///
  /// // For Product list response
  /// final response = ApiResponse<List<Product>>.fromJson(
  ///   json,
  ///   (data) => (data as List)
  ///       .map((item) => Product.fromJson(item))
  ///       .toList(),
  /// );
  /// ```
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);
}

// ============================================================================
// HELPER CONSTRUCTORS
// ============================================================================
// These factory constructors make it easier to create common response types

extension ApiResponseExtension<T> on ApiResponse<T> {
  /// Creates a success response
  ///
  /// WHEN TO USE:
  /// When an API call succeeds and you have data to return
  ///
  /// EXAMPLE:
  /// ```dart
  /// final user = User(id: 1, username: 'john', ...);
  /// return ApiResponse.success(
  ///   data: user,
  ///   message: 'Login successful',
  /// );
  /// ```
  static ApiResponse<T> success<T>({
    required T data,
    String? message,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message ?? 'Success',
      statusCode: statusCode ?? 200,
    );
  }

  /// Creates an error response
  ///
  /// WHEN TO USE:
  /// When an API call fails
  ///
  /// EXAMPLE:
  /// ```dart
  /// return ApiResponse.error(
  ///   message: 'Login failed',
  ///   error: 'Invalid username or password',
  ///   statusCode: 401,
  /// );
  /// ```
  static ApiResponse<T> error<T>({
    required String message,
    String? error,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      error: error,
      statusCode: statusCode ?? 400,
    );
  }
}

// ============================================================================
// 📚 LEARNING NOTES
// ============================================================================
//
// KEY CONCEPTS:
//
// 1. GENERICS (<T>):
//    T is a placeholder for any type
//    When you use ApiResponse<User>, T becomes User
//    When you use ApiResponse<Product>, T becomes Product
//
//    BENEFITS:
//    - Type safety: response.data is typed as User, not dynamic
//    - Code reuse: One class for all response types
//    - Better autocomplete: IDE knows the exact type
//
//    EXAMPLE:
//    ```dart
//    // Without generics (bad)
//    class ApiResponse {
//      dynamic data; // Could be anything!
//    }
//    final response = ApiResponse();
//    final user = response.data as User; // Manual casting, error-prone
//
//    // With generics (good)
//    class ApiResponse<T> {
//      T? data; // Typed!
//    }
//    final response = ApiResponse<User>();
//    final user = response.data; // Already typed as User?, safe!
//    ```
//
// 2. NULLABLE DATA (T?):
//    Error responses might not have data, so data is nullable
//
//    SAFE ACCESS:
//    ```dart
//    // Option 1: Null check
//    if (response.data != null) {
//      print(response.data!.username);
//    }
//
//    // Option 2: Null-aware operator
//    print(response.data?.username);
//
//    // Option 3: Provide default
//    final user = response.data ?? User.empty();
//    ```
//
// 3. SUCCESS vs ERROR:
//    ```dart
//    if (response.success) {
//      // Happy path - use response.data
//      final user = response.data!;
//      navigateToHome(user);
//    } else {
//      // Error path - show response.message or response.error
//      showError(response.message ?? response.error ?? 'Unknown error');
//    }
//    ```
//
// 4. STATUS CODES:
//    Common HTTP status codes:
//
//    SUCCESS (2xx):
//    - 200 OK: Request succeeded
//    - 201 Created: Resource created successfully
//    - 204 No Content: Success but no data to return
//
//    CLIENT ERRORS (4xx):
//    - 400 Bad Request: Invalid data sent
//    - 401 Unauthorized: Not authenticated
//    - 403 Forbidden: Not authorized
//    - 404 Not Found: Resource doesn't exist
//    - 422 Unprocessable Entity: Validation failed
//
//    SERVER ERRORS (5xx):
//    - 500 Internal Server Error: Server crashed
//    - 502 Bad Gateway: Server temporarily down
//    - 503 Service Unavailable: Server overloaded
//
// 5. ERROR HANDLING PATTERN:
//    ```dart
//    try {
//      final response = await apiClient.post('/login', {...});
//      final user = User.fromJson(response);
//      return ApiResponse.success(data: user);
//    } on HttpException catch (e) {
//      return ApiResponse.error(
//        message: 'Network error',
//        error: e.message,
//        statusCode: e.statusCode,
//      );
//    } catch (e) {
//      return ApiResponse.error(
//        message: 'Unexpected error',
//        error: e.toString(),
//      );
//    }
//    ```
//
// 6. WHY NOT THROW EXCEPTIONS?
//    You COULD throw exceptions for errors:
//    ```dart
//    if (response.statusCode != 200) {
//      throw Exception('Login failed');
//    }
//    ```
//
//    But using ApiResponse is better because:
//    - More explicit (caller knows to check success)
//    - Easier to handle (no try-catch needed everywhere)
//    - Carries more info (message, error, status code)
//    - Type-safe (compiler enforces checking)
//
//    EXCEPTIONS: Use for truly unexpected errors (null pointer, etc.)
//    API_RESPONSE: Use for expected failures (invalid input, auth failed)
//
// ============================================================================
// 🎯 USAGE EXAMPLES
// ============================================================================
//
// IN SERVICE LAYER:
// ```dart
// class AuthService {
//   Future<ApiResponse<User>> login(String username, String password) async {
//     try {
//       final json = await apiClient.post('/auth/login', {
//         'username': username,
//         'password': password,
//       });
//
//       final user = User.fromJson(json);
//
//       return ApiResponse.success(
//         data: user,
//         message: 'Login successful',
//       );
//     } catch (e) {
//       return ApiResponse.error(
//         message: 'Login failed',
//         error: e.toString(),
//       );
//     }
//   }
// }
// ```
//
// IN PROVIDER LAYER:
// ```dart
// class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
//   Future<void> login(String username, String password) async {
//     state = const AsyncValue.loading();
//
//     final response = await authService.login(username, password);
//
//     if (response.success && response.data != null) {
//       state = AsyncValue.data(response.data);
//     } else {
//       state = AsyncValue.error(
//         response.error ?? response.message ?? 'Unknown error',
//         StackTrace.current,
//       );
//     }
//   }
// }
// ```
//
// IN UI LAYER:
// ```dart
// final response = await authService.login(username, password);
//
// if (response.success) {
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(content: Text(response.message ?? 'Success')),
//   );
//   Navigator.pushReplacement(context, HomeScreen());
// } else {
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       content: Text(response.error ?? 'An error occurred'),
//       backgroundColor: Colors.red,
//     ),
//   );
// }
// ```
//
// ============================================================================
// 🎯 YOUR TASK
// ============================================================================
//
// You'll use ApiResponse when implementing the signup feature!
// It makes error handling much cleaner and more consistent.
//
// CHALLENGE:
// Create a service method that returns ApiResponse<List<Product>>
// and handles all possible errors gracefully!
//
// ============================================================================
