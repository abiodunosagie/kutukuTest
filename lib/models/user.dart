// ============================================================================
// USER MODEL
// ============================================================================
// This file defines the User data structure (model/entity).
//
// WHY DO WE NEED MODELS?
// When we receive data from an API (as JSON), we need to convert it into
// Dart objects that we can work with. Models provide:
// - Type safety (know what fields exist)
// - Autocomplete (IDE suggestions)
// - Compile-time checks (catch errors before running)
// - Easy JSON conversion (to/from JSON)
//
// WHAT IS FREEZED?
// Freezed is a code generation library that creates:
// - Immutable classes (can't accidentally modify data)
// - copyWith method (create modified copies)
// - Equality operators (compare objects easily)
// - toString method (debug printing)
// - JSON serialization (automatic conversion)
//
// WHY IMMUTABLE?
// Immutable objects can't be changed after creation. This prevents bugs
// where data changes unexpectedly.
// ============================================================================

// Import the freezed annotation package
// This provides the @freezed decorator we use below
import 'package:freezed_annotation/freezed_annotation.dart';

// ============================================================================
// PART DIRECTIVES
// ============================================================================
// These tell Dart to generate additional files for this model
//
// WHAT ARE PART FILES?
// Part files are additional code that belongs to this file but is generated
// automatically by build_runner.
//
// WHY 'user.freezed.dart' and 'user.g.dart'?
// - .freezed.dart: Contains freezed-generated code (copyWith, equality, etc.)
// - .g.dart: Contains JSON serialization code (fromJson, toJson)
//
// HOW TO GENERATE THESE FILES:
// Run this command in terminal:
// flutter pub run build_runner build --delete-conflicting-outputs
//
// The files don't exist yet, but Dart knows they will exist after running
// the build_runner command.
part 'user.freezed.dart'; // Will contain freezed generated code
part 'user.g.dart'; // Will contain JSON serialization code

// ============================================================================
// USER CLASS DEFINITION
// ============================================================================

/// Represents a user in the system
///
/// This model matches the structure returned by the DummyJSON API.
/// API Response example:
/// ```json
/// {
///   "id": 1,
///   "username": "emilys",
///   "email": "emily.johnson@x.dummyjson.com",
///   "firstName": "Emily",
///   "lastName": "Johnson",
///   "gender": "female",
///   "image": "https://dummyjson.com/icon/emilys/128",
///   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
/// }
/// ```
///
/// IMMUTABILITY:
/// Once created, a User object cannot be modified. To "change" a user,
/// you create a new User object with the changed values:
/// ```dart
/// final user = User(id: 1, username: 'john', email: 'john@example.com');
/// final updatedUser = user.copyWith(username: 'john_doe'); // New object!
/// ```
@freezed
class User with _$User {
  // ==========================================================================
  // FACTORY CONSTRUCTOR
  // ==========================================================================
  // The factory constructor defines what fields the User has
  //
  // WHY 'const factory'?
  // - const: Creates a compile-time constant (better performance)
  // - factory: Allows freezed to generate the implementation
  //
  // FIELD TYPES:
  // - required: This field MUST be provided when creating a User
  // - optional: This field can be null (marked with ?)

  const factory User({
    /// Unique identifier for the user
    /// This comes from the database and is set by the server
    /// REQUIRED: Every user must have an ID
    required int id,

    /// Username for login
    /// REQUIRED: Used for authentication
    /// Example: "emilys", "johndoe"
    required String username,

    /// User's email address
    /// REQUIRED: Used for communication and password reset
    /// Example: "emily.johnson@x.dummyjson.com"
    required String email,

    /// User's first name
    /// OPTIONAL: Might not be provided during registration
    /// The ? means this can be null
    /// Example: "Emily"
    String? firstName,

    /// User's last name
    /// OPTIONAL: Might not be provided during registration
    /// Example: "Johnson"
    String? lastName,

    /// User's gender
    /// OPTIONAL: Personal information, not always required
    /// Example: "female", "male", "other"
    String? gender,

    /// URL to user's profile image
    /// OPTIONAL: User might not have uploaded a photo
    /// Example: "https://dummyjson.com/icon/emilys/128"
    String? image,

    /// Authentication token (JWT)
    /// OPTIONAL: Only present after login/signup
    /// This token is sent with API requests to prove identity
    /// Example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    ///
    /// NOTE: In a real app, you might not include this in the User model
    /// and instead store it separately for security reasons
    String? token,

    /// Refresh token for getting new auth tokens
    /// OPTIONAL: Used when the auth token expires
    /// Not provided by DummyJSON, but included for real-world use
    String? refreshToken,
  }) = _User;

  // ==========================================================================
  // JSON SERIALIZATION
  // ==========================================================================

  /// Creates a User object from JSON data
  ///
  /// WHEN IS THIS USED?
  /// When you receive data from an API, it comes as JSON (a string or map).
  /// This method converts that JSON into a User object you can work with.
  ///
  /// HOW IT WORKS:
  /// 1. API returns: {"id": 1, "username": "john", "email": "john@example.com"}
  /// 2. We parse it: Map<String, dynamic> json = jsonDecode(response.body)
  /// 3. We call: User user = User.fromJson(json)
  /// 4. We get: A User object with all fields populated
  ///
  /// THE MAGIC:
  /// The actual implementation is in user.g.dart (auto-generated)
  /// Freezed and json_serializable work together to create this automatically
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// // JSON from API
  /// final json = {
  ///   'id': 1,
  ///   'username': 'emilys',
  ///   'email': 'emily@example.com',
  ///   'firstName': 'Emily',
  /// };
  ///
  /// // Convert to User object
  /// final user = User.fromJson(json);
  ///
  /// // Now you can access fields with type safety
  /// print(user.username); // "emilys"
  /// print(user.firstName); // "Emily"
  /// ```
  ///
  /// ERROR HANDLING:
  /// If the JSON structure doesn't match (e.g., missing required fields),
  /// this will throw an error. Always wrap in try-catch when parsing
  /// untrusted data:
  /// ```dart
  /// try {
  ///   final user = User.fromJson(json);
  /// } catch (e) {
  ///   print('Failed to parse user: $e');
  /// }
  /// ```
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  // toJson method is automatically generated by freezed
  // It's available as: user.toJson()
  // This converts a User object back to JSON (for sending to API)
}

// ============================================================================
// 📚 LEARNING NOTES
// ============================================================================
//
// KEY CONCEPTS:
//
// 1. FREEZED ANNOTATIONS:
//    - @freezed: Tells freezed to generate code for this class
//    - const factory: Creates an immutable data class
//    - with _$User: Mixin that includes generated code
//    - = _User: Default implementation name
//
// 2. JSON SERIALIZATION:
//    Map<String, dynamic> = JSON object in Dart
//    - String: The keys (field names)
//    - dynamic: The values (can be any type)
//
//    Example:
//    {
//      "id": 1,           // int
//      "username": "bob", // String
//      "active": true,    // bool
//      "age": null        // null
//    }
//
// 3. REQUIRED vs OPTIONAL:
//    - required int id: Must be provided, never null
//    - String? name: Optional, can be null
//
//    When to use which?
//    - required: Data that ALWAYS exists (id, username, email)
//    - optional: Data that MIGHT exist (firstName, image, token)
//
// 4. IMMUTABILITY:
//    Once created, User objects can't change:
//    ```dart
//    final user = User(id: 1, username: 'john', email: 'j@example.com');
//    user.username = 'jane'; // ❌ ERROR! Can't modify
//
//    // Instead, create a new object:
//    final newUser = user.copyWith(username: 'jane'); // ✅
//    ```
//
//    WHY?
//    Prevents accidental mutations, makes code more predictable
//
// 5. PART FILES:
//    - user.dart: Your code (this file)
//    - user.freezed.dart: Freezed generated code (copyWith, ==, toString)
//    - user.g.dart: JSON serialization code (fromJson, toJson)
//
//    You write user.dart, build_runner generates the other two
//
// 6. CODE GENERATION COMMAND:
//    Run this to generate .freezed.dart and .g.dart files:
//    ```
//    flutter pub run build_runner build --delete-conflicting-outputs
//    ```
//
//    Flags explained:
//    - build: Generate files
//    - --delete-conflicting-outputs: Overwrite existing generated files
//
//    During development, use watch mode (auto-regenerates on save):
//    ```
//    flutter pub run build_runner watch
//    ```
//
// 7. WHY NOT MANUAL CLASSES?
//    You COULD write everything manually:
//    ```dart
//    class User {
//      final int id;
//      final String username;
//      User({required this.id, required this.username});
//
//      factory User.fromJson(Map<String, dynamic> json) {
//        return User(
//          id: json['id'],
//          username: json['username'],
//        );
//      }
//
//      Map<String, dynamic> toJson() {
//        return {'id': id, 'username': username};
//      }
//
//      User copyWith({int? id, String? username}) {
//        return User(
//          id: id ?? this.id,
//          username: username ?? this.username,
//        );
//      }
//
//      @override
//      bool operator ==(Object other) {
//        // ... complex equality logic
//      }
//
//      @override
//      int get hashCode {
//        // ... complex hash logic
//      }
//    }
//    ```
//
//    But freezed does ALL of this automatically! Less code, fewer bugs.
//
// ============================================================================
// 🎯 USAGE EXAMPLES
// ============================================================================
//
// CREATE a User:
// ```dart
// final user = User(
//   id: 1,
//   username: 'emilys',
//   email: 'emily@example.com',
//   firstName: 'Emily',
// );
// ```
//
// PARSE from JSON:
// ```dart
// final json = {'id': 1, 'username': 'emilys', 'email': 'emily@example.com'};
// final user = User.fromJson(json);
// ```
//
// CONVERT to JSON:
// ```dart
// final json = user.toJson();
// // Result: {'id': 1, 'username': 'emilys', 'email': 'emily@example.com', ...}
// ```
//
// COPY with changes:
// ```dart
// final updatedUser = user.copyWith(
//   firstName: 'Emily Jane',
//   lastName: 'Doe',
// );
// // All other fields remain the same, only firstName and lastName change
// ```
//
// COMPARE Users:
// ```dart
// final user1 = User(id: 1, username: 'john', email: 'john@example.com');
// final user2 = User(id: 1, username: 'john', email: 'john@example.com');
// print(user1 == user2); // true (same values)
// ```
//
// DEBUG PRINT:
// ```dart
// print(user.toString());
// // Output: User(id: 1, username: emilys, email: emily@example.com, ...)
// ```
//
// ACCESS fields:
// ```dart
// print(user.username); // emilys
// print(user.firstName); // Emily
// print(user.token ?? 'No token'); // Token or 'No token' if null
// ```
//
// ============================================================================
// 🐛 COMMON ERRORS
// ============================================================================
//
// ERROR: "part of 'user.dart' must be a part directive"
// SOLUTION: Run build_runner to generate the part files
//
// ERROR: "The getter 'toJson' isn't defined"
// SOLUTION: Run build_runner to generate JSON serialization
//
// ERROR: "Required named parameter 'id' must be provided"
// SOLUTION: Provide all required fields when creating User
//
// ERROR: "The argument type 'String' can't be assigned to 'int'"
// SOLUTION: Ensure JSON field types match model (e.g., id should be int)
//
// ============================================================================
// 🎯 YOUR TASK
// ============================================================================
//
// After running build_runner, you'll use this User model in:
// 1. AuthService (to return user after login)
// 2. AuthProvider (to store current user state)
// 3. Login/Signup screens (to display user info)
//
// NEXT: Create the Product model following the same pattern!
//
// ============================================================================
