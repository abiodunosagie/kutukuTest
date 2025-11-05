// ============================================================================
// STORAGE SERVICE
// ============================================================================
// This file handles secure storage of sensitive data (like auth tokens).
//
// WHY WE NEED THIS:
// - Auth tokens are like passwords - they prove you're logged in
// - They must be stored SECURELY (not in plain text)
// - They must PERSIST (survive app restarts)
// - They must be ACCESSIBLE (for API calls)
//
// WHAT IS FLUTTER_SECURE_STORAGE?
// It uses platform-specific secure storage:
// - iOS: Keychain
// - Android: Keystore
// - Both are encrypted and protected by the OS
//
// WHY NOT SharedPreferences?
// SharedPreferences stores data in plain text files - anyone with device
// access can read them! Secure storage encrypts the data.
// ============================================================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ============================================================================
// STORAGE SERVICE CLASS
// ============================================================================
// This class provides methods to save, retrieve, and delete secure data.
//
// DESIGN PATTERN: Singleton-like (but without enforcing it)
// We'll create one instance via Riverpod and reuse it everywhere.
class StorageService {
  // ==========================================================================
  // PRIVATE PROPERTIES
  // ==========================================================================

  // The FlutterSecureStorage instance that does the actual storage work
  //
  // WHY FINAL?
  // Once set, we don't want to replace this instance (it could cause bugs)
  //
  // WHY CONST?
  // FlutterSecureStorage() creates the same instance every time, so we can
  // make it const for better performance
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ==========================================================================
  // STORAGE KEYS
  // ==========================================================================
  // Keys are like labels on storage boxes - they identify what's stored
  //
  // WHY STATIC CONST?
  // - static: Can be accessed without creating an instance
  // - const: Never changes
  //
  // WHY PREFIX WITH UNDERSCORE?
  // Underscore makes them private (only accessible in this file)
  //
  // WHY USE CONSTANTS?
  // If you typo "auth_token" as "auth_tokn", you'll lose access to the token!
  // Constants prevent typos through autocomplete.

  /// Key for storing the authentication token
  /// This token is sent with every API request to prove you're logged in
  static const String _tokenKey = 'auth_token';

  /// Key for storing the refresh token
  /// Used to get a new auth token when the current one expires
  static const String _refreshTokenKey = 'refresh_token';

  /// Key for storing the user ID
  /// Sometimes useful to have quick access to the user's ID without
  /// decoding the token
  static const String _userIdKey = 'user_id';

  // ==========================================================================
  // AUTH TOKEN METHODS
  // ==========================================================================

  /// Saves the authentication token securely
  ///
  /// WHEN TO CALL THIS:
  /// After successful login or signup, when the server returns a token
  ///
  /// WHAT HAPPENS:
  /// 1. Takes the token string as input
  /// 2. Encrypts it using platform-specific encryption
  /// 3. Stores it securely on the device
  ///
  /// WHY ASYNC?
  /// Writing to storage takes time (disk I/O), so we use async/await
  /// to avoid blocking the UI thread
  ///
  /// WHY FUTURE<void>?
  /// - Future: This operation completes later (asynchronously)
  /// - void: This method doesn't return anything, it just saves
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// await storageService.saveToken('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...');
  /// ```
  Future<void> saveToken(String token) async {
    // Call the _storage.write method
    // - key: Identifies what we're storing
    // - value: The actual data to store
    //
    // The await keyword makes Dart wait until the storage operation completes
    await _storage.write(
      key: _tokenKey,
      value: token,
    );
  }

  /// Retrieves the stored authentication token
  ///
  /// WHEN TO CALL THIS:
  /// Before making authenticated API requests, to include the token in headers
  ///
  /// WHAT HAPPENS:
  /// 1. Looks for data stored under the _tokenKey
  /// 2. Decrypts it (if found)
  /// 3. Returns the token string
  ///
  /// WHY FUTURE<String?>?
  /// - Future: This operation completes later (asynchronously)
  /// - String?: Returns a String OR null (if no token is stored)
  ///   The ? means "nullable" - the token might not exist
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// final token = await storageService.getToken();
  /// if (token != null) {
  ///   // Use token in API request
  /// } else {
  ///   // User is not logged in
  /// }
  /// ```
  Future<String?> getToken() async {
    // Read the value associated with _tokenKey
    // Returns null if no value is stored
    return await _storage.read(key: _tokenKey);
  }

  /// Deletes the stored authentication token
  ///
  /// WHEN TO CALL THIS:
  /// During logout, to clear the user's session
  ///
  /// WHAT HAPPENS:
  /// Removes the token from secure storage
  ///
  /// WHY FUTURE<void>?
  /// Deleting from storage takes time, so it's async
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// await storageService.deleteToken();
  /// // User is now logged out
  /// ```
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // ==========================================================================
  // REFRESH TOKEN METHODS
  // ==========================================================================
  // Refresh tokens are long-lived tokens used to get new auth tokens
  // Most APIs use this pattern for security:
  // - Auth token: Short-lived (15 minutes), used for API requests
  // - Refresh token: Long-lived (30 days), used to get new auth tokens

  /// Saves the refresh token securely
  ///
  /// WHEN TO CALL THIS:
  /// When the server provides a refresh token (usually during login)
  ///
  /// NOTE: DummyJSON doesn't actually use refresh tokens, but real apps do!
  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(
      key: _refreshTokenKey,
      value: refreshToken,
    );
  }

  /// Retrieves the stored refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Deletes the stored refresh token
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  // ==========================================================================
  // USER ID METHODS
  // ==========================================================================

  /// Saves the user ID
  ///
  /// WHEN TO CALL THIS:
  /// After login, to quickly access the user's ID without API calls
  ///
  /// WHY STORE USER ID?
  /// Some operations need the user ID (e.g., fetching user's cart)
  /// Storing it saves you from making extra API calls
  Future<void> saveUserId(int userId) async {
    // Convert int to String because storage only accepts strings
    await _storage.write(
      key: _userIdKey,
      value: userId.toString(),
    );
  }

  /// Retrieves the stored user ID
  ///
  /// RETURNS:
  /// The user ID as an integer, or null if not stored
  Future<int?> getUserId() async {
    final userIdString = await _storage.read(key: _userIdKey);

    // If no user ID is stored, return null
    if (userIdString == null) return null;

    // Convert String back to int
    // int.tryParse returns null if the string isn't a valid number
    return int.tryParse(userIdString);
  }

  /// Deletes the stored user ID
  Future<void> deleteUserId() async {
    await _storage.delete(key: _userIdKey);
  }

  // ==========================================================================
  // GENERAL PURPOSE METHODS
  // ==========================================================================

  /// Saves any key-value pair securely
  ///
  /// USE CASE:
  /// When you need to store other sensitive data beyond tokens
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// await storageService.saveValue('user_email', 'user@example.com');
  /// ```
  Future<void> saveValue(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Retrieves any value by key
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// final email = await storageService.getValue('user_email');
  /// ```
  Future<String?> getValue(String key) async {
    return await _storage.read(key: key);
  }

  /// Deletes any value by key
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// await storageService.deleteValue('user_email');
  /// ```
  Future<void> deleteValue(String key) async {
    await _storage.delete(key: key);
  }

  // ==========================================================================
  // CLEAR ALL DATA
  // ==========================================================================

  /// Deletes ALL stored data
  ///
  /// WHEN TO CALL THIS:
  /// - During logout (to completely clear the session)
  /// - When user deletes their account
  /// - During app reset/reinstall
  ///
  /// ⚠️ WARNING:
  /// This is destructive! It removes EVERYTHING from secure storage.
  /// Make sure this is what you want!
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// await storageService.clearAll();
  /// // All secure data is now gone
  /// ```
  Future<void> clearAll() async {
    // deleteAll() removes every key-value pair from secure storage
    await _storage.deleteAll();
  }

  // ==========================================================================
  // CHECK IF USER IS LOGGED IN
  // ==========================================================================

  /// Checks if a user is currently logged in
  ///
  /// HOW IT WORKS:
  /// A user is considered logged in if they have a valid token
  ///
  /// RETURNS:
  /// true if token exists, false otherwise
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// final isLoggedIn = await storageService.isLoggedIn();
  /// if (isLoggedIn) {
  ///   // Navigate to home screen
  /// } else {
  ///   // Navigate to login screen
  /// }
  /// ```
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    // If token is not null, user is logged in
    return token != null;
  }
}

// ============================================================================
// 📚 LEARNING NOTES
// ============================================================================
//
// KEY CONCEPTS:
//
// 1. ASYNC/AWAIT:
//    - Async operations don't block the UI
//    - 'async' keyword: Marks a function as asynchronous
//    - 'await' keyword: Waits for an async operation to complete
//    - Future<T>: Represents a value that will be available later
//
//    Example flow:
//    ```dart
//    Future<String?> getToken() async {  // async function
//      return await _storage.read(...);  // wait for storage operation
//    }
//
//    // Using it:
//    final token = await storageService.getToken();  // wait for result
//    ```
//
// 2. NULLABLE TYPES (String?):
//    - String: Always has a value (never null)
//    - String?: Can be a String OR null
//
//    Why use nullable?
//    A token might not exist (user hasn't logged in yet), so we need
//    to represent "no value" with null.
//
// 3. SECURE STORAGE vs SharedPreferences vs In-Memory:
//
//    | Storage Type       | Security | Persistence | Use Case              |
//    |--------------------|----------|-------------|-----------------------|
//    | Secure Storage     | High     | Yes         | Tokens, passwords     |
//    | SharedPreferences  | None     | Yes         | Settings, preferences |
//    | In-Memory (var)    | Medium   | No          | Temporary data        |
//
// 4. PRIVATE PROPERTIES (underscore):
//    - _storage: Only accessible in this file
//    - storage: Would be accessible from other files
//
//    We use private to encapsulate implementation details.
//
// 5. CONST vs FINAL:
//    - const: Compile-time constant (value known before running)
//    - final: Runtime constant (value set once when initialized)
//
//    ```dart
//    const _tokenKey = 'auth_token';  // Known at compile time
//    final _storage = FlutterSecureStorage();  // Set at runtime
//    ```
//
// 6. ERROR HANDLING:
//    Currently, these methods don't catch errors. In production, you might
//    want to wrap operations in try-catch blocks:
//
//    ```dart
//    Future<void> saveToken(String token) async {
//      try {
//        await _storage.write(key: _tokenKey, value: token);
//      } catch (e) {
//        // Handle error (log it, show message, etc.)
//        print('Failed to save token: $e');
//      }
//    }
//    ```
//
// ============================================================================
// 🔐 SECURITY BEST PRACTICES
// ============================================================================
//
// ✅ DO:
// - Store tokens in secure storage
// - Clear tokens on logout
// - Use HTTPS for API calls (tokens in transit)
// - Implement token refresh logic
// - Set token expiration times
//
// ❌ DON'T:
// - Store tokens in SharedPreferences (not encrypted!)
// - Log tokens to console in production
// - Share tokens between users/devices
// - Store tokens in git repositories
// - Use tokens as API keys (different concepts!)
//
// ============================================================================
// 🎯 NEXT STEPS
// ============================================================================
//
// Now that you can store tokens securely, you'll:
// 1. Create an API client that uses these tokens
// 2. Create services that save tokens after login
// 3. Create providers that check if users are logged in
// 4. Update UI based on login state
//
// ============================================================================
