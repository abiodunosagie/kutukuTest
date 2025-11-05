// ============================================================================
// API RESPONSE MODEL
// ============================================================================
// This file defines a generic wrapper for API responses.
//
// SIMPLIFIED VERSION:
// This version doesn't use Freezed or JSON serialization because:
// 1. Generic types (T) are complex with json_serializable
// 2. We don't actually deserialize to ApiResponse in our code
// 3. We convert JSON directly to User, Product, etc.
//
// This class is mainly used for:
// - Consistent response structure in services
// - Type-safe response handling
// - Clear success/failure states
// ============================================================================

/// Generic wrapper for API responses
///
/// GENERIC TYPE PARAMETER <T>:
/// T represents the type of data this response contains
/// Example: ApiResponse<User>, ApiResponse<Product>, ApiResponse<List<Product>>
///
/// EXAMPLE RESPONSES:
///
/// SUCCESS:
/// ```dart
/// ApiResponse<User>(
///   success: true,
///   message: "Login successful",
///   data: user,
/// )
/// ```
///
/// ERROR:
/// ```dart
/// ApiResponse<User>(
///   success: false,
///   message: "Invalid credentials",
///   error: "Authentication failed",
/// )
/// ```
class ApiResponse<T> {
  /// Indicates if the request was successful
  /// true = success, false = error
  final bool success;

  /// Human-readable message
  /// Success: "Login successful", "Product added to cart"
  /// Error: "Invalid credentials", "Product out of stock"
  final String? message;

  /// The actual data returned by the API
  /// Can be any type: User, Product, List<Product>, etc.
  ///
  /// WHY NULLABLE?
  /// - Success responses have data
  /// - Error responses might not have data
  final T? data;

  /// Error details (if request failed)
  /// Only present when success = false
  final String? error;

  /// HTTP status code (optional)
  /// 200 = OK, 404 = Not Found, 500 = Server Error, etc.
  final int? statusCode;

  /// Creates an ApiResponse
  const ApiResponse({
    this.success = true,
    this.message,
    this.data,
    this.error,
    this.statusCode,
  });

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
  factory ApiResponse.success({
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
  factory ApiResponse.error({
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

  /// Checks if the response has data
  bool get hasData => data != null;

  /// Checks if the response has error
  bool get hasError => error != null;

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, data: $data, error: $error, statusCode: $statusCode)';
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
// 4. WHY NO JSON SERIALIZATION?
//    For generic types, JSON serialization is complex.
//    Instead, we:
//    - Convert JSON directly to specific types (User, Product)
//    - Use ApiResponse for in-memory response handling
//    - Don't serialize/deserialize ApiResponse itself
//
//    Example flow:
//    ```dart
//    // In service
//    final json = await apiClient.post('/login', {...});
//    final user = User.fromJson(json);  // Direct conversion
//    return ApiResponse.success(data: user);  // Wrap in response
//    ```
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
