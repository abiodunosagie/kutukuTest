// ============================================================================
// AUTHENTICATION SERVICE
// ============================================================================
// This service handles all authentication-related operations.
//
// RESPONSIBILITIES:
// 1. Login (authenticate user)
// 2. Signup (create new account)
// 3. Logout (clear session)
// 4. Get current user
// 5. Check if user is logged in
//
// ARCHITECTURE:
// UI Layer → AuthService → ApiClient → Server
//
// WHY A SEPARATE SERVICE?
// - Separates business logic from UI
// - Makes testing easier
// - Reusable across different screens
// - Encapsulates authentication logic
// ============================================================================

import 'package:kutuku/models/user.dart';
import 'package:kutuku/services/api_client.dart';
import 'package:kutuku/utils/api_constants.dart';
import 'package:kutuku/utils/storage_service.dart';

// ============================================================================
// AUTH SERVICE CLASS
// ============================================================================

/// Service for handling authentication operations
///
/// This class contains the business logic for authentication.
/// It uses ApiClient to communicate with the server and StorageService
/// to manage tokens.
///
/// DESIGN PATTERN: Service Layer Pattern
/// Keeps business logic separate from UI and API layers
class AuthService {
  // ==========================================================================
  // PROPERTIES
  // ==========================================================================

  /// API client for making HTTP requests
  /// All network calls go through this client
  ///
  /// WHY FINAL?
  /// Once injected, we don't want to replace it (prevents bugs)
  final ApiClient _apiClient;

  /// Storage service for managing tokens
  /// We use this to save/retrieve/delete auth tokens
  final StorageService _storageService;

  // ==========================================================================
  // CONSTRUCTOR
  // ==========================================================================

  /// Creates an AuthService instance
  ///
  /// PARAMETERS:
  /// - _apiClient: The HTTP client for API calls
  /// - _storageService: The storage service for tokens
  ///
  /// EXAMPLE USAGE (via Riverpod):
  /// ```dart
  /// final authService = ref.watch(authServiceProvider);
  /// ```
  ///
  /// NOTE: You don't create this manually - Riverpod does it for you!
  AuthService(this._apiClient, this._storageService);

  // ==========================================================================
  // LOGIN
  // ==========================================================================

  /// Authenticates a user with username and password
  ///
  /// THE LOGIN FLOW:
  /// ```
  /// 1. User enters username & password in UI
  /// 2. UI calls authService.login(username, password)
  /// 3. AuthService sends POST request to /auth/login
  /// 4. Server validates credentials
  /// 5. Server returns user data + auth token
  /// 6. AuthService saves token to secure storage
  /// 7. AuthService converts JSON to User object
  /// 8. AuthService returns User to UI
  /// 9. UI navigates to home screen
  /// ```
  ///
  /// API ENDPOINT:
  /// POST /auth/login
  ///
  /// REQUEST BODY:
  /// ```json
  /// {
  ///   "username": "emilys",
  ///   "password": "emilyspass"
  /// }
  /// ```
  ///
  /// RESPONSE (Success):
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
  /// PARAMETERS:
  /// - username: User's username or email
  /// - password: User's password
  ///
  /// RETURNS:
  /// User object with all user data
  ///
  /// THROWS:
  /// - HttpException: If login fails (invalid credentials, network error, etc.)
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// try {
  ///   final user = await authService.login('emilys', 'emilyspass');
  ///   print('Logged in as: ${user.username}');
  ///   // Navigate to home screen
  /// } catch (e) {
  ///   print('Login failed: $e');
  ///   // Show error message to user
  /// }
  /// ```
  ///
  /// STEP-BY-STEP BREAKDOWN:
  Future<User> login(String username, String password) async {
    // STEP 1: Make API call to login endpoint
    // We use POST because we're sending credentials (sensitive data)
    // includeAuth: false because we don't have a token yet (not logged in!)
    final response = await _apiClient.post(
      ApiConstants.login, // The endpoint: '/auth/login'
      body: {
        // Request body - the data we're sending to the server
        'username': username, // The username entered by user
        'password': password, // The password entered by user
        // Note: In production, NEVER log passwords!
      },
      includeAuth: false, // Don't include auth token (we don't have one yet!)
    );

    // At this point, response is a Map<String, dynamic> with the server's response
    // Example: {id: 1, username: 'emilys', token: 'eyJ...', ...}

    // STEP 2: Extract and save the auth token
    // The server includes a JWT token in the response
    // We need to save this token for future authenticated requests
    if (response['token'] != null) {
      // Token exists in response, save it securely
      final token = response['token'] as String;

      // Save to secure storage (encrypted)
      await _storageService.saveToken(token);

      // Also save user ID for quick access
      if (response['id'] != null) {
        await _storageService.saveUserId(response['id'] as int);
      }

      // Log for debugging (remove in production!)
      print('Token saved successfully');
    } else {
      // No token in response - this shouldn't happen
      // If it does, something is wrong with the API
      print('Warning: Login response did not include a token');
    }

    // STEP 3: Convert JSON response to User object
    // We use the User.fromJson factory to convert the Map to a User object
    // This gives us type safety and easy access to user data
    final user = User.fromJson(response);

    // Log the successful login (for debugging)
    print('Login successful: ${user.username}');

    // STEP 4: Return the User object
    // The calling code (usually a provider) will use this to update state
    return user;
  }

  // ==========================================================================
  // SIGNUP (REGISTER)
  // ==========================================================================

  /// Creates a new user account
  ///
  /// THE SIGNUP FLOW:
  /// ```
  /// 1. User enters username, email, password in UI
  /// 2. UI validates input (password strength, email format, etc.)
  /// 3. UI calls authService.signup(...)
  /// 4. AuthService sends POST request to /users/add
  /// 5. Server validates data (unique username, etc.)
  /// 6. Server creates user in database
  /// 7. Server returns user data
  /// 8. AuthService converts JSON to User object
  /// 9. AuthService returns User to UI
  /// 10. UI shows success message
  /// 11. UI navigates to login or home screen
  /// ```
  ///
  /// API ENDPOINT:
  /// POST /users/add
  ///
  /// REQUEST BODY:
  /// ```json
  /// {
  ///   "username": "johndoe",
  ///   "email": "john@example.com",
  ///   "password": "john123",
  ///   "firstName": "John",
  ///   "lastName": "Doe"
  /// }
  /// ```
  ///
  /// RESPONSE (Success):
  /// ```json
  /// {
  ///   "id": 210,
  ///   "username": "johndoe",
  ///   "email": "john@example.com",
  ///   "firstName": "John",
  ///   "lastName": "Doe"
  /// }
  /// ```
  ///
  /// NOTE: DummyJSON doesn't return a token for signup, so after signup
  /// you should navigate to login screen. In a real app, you might auto-login.
  ///
  /// PARAMETERS:
  /// - username: Desired username (must be unique)
  /// - email: User's email address (must be valid)
  /// - password: User's password (must meet strength requirements)
  /// - firstName: Optional first name
  /// - lastName: Optional last name
  ///
  /// RETURNS:
  /// User object with the newly created user data
  ///
  /// THROWS:
  /// - HttpException: If signup fails (username taken, invalid email, etc.)
  ///
  /// 🎯 YOUR TASK:
  /// Implement this method following the same pattern as login!
  ///
  /// HINTS:
  /// 1. Use _apiClient.post()
  /// 2. Endpoint: ApiConstants.register
  /// 3. Include all parameters in the body
  /// 4. includeAuth: false (not logged in yet)
  /// 5. No token to save (DummyJSON doesn't return one for signup)
  /// 6. Convert response to User with User.fromJson()
  /// 7. Return the User object
  ///
  /// EXAMPLE IMPLEMENTATION:
  /// ```dart
  /// Future<User> signup({
  ///   required String username,
  ///   required String email,
  ///   required String password,
  ///   String? firstName,
  ///   String? lastName,
  /// }) async {
  ///   // TODO: Make API call
  ///   // TODO: Convert response to User
  ///   // TODO: Return user
  /// }
  /// ```
  ///
  /// TEST WITH:
  /// ```dart
  /// final user = await authService.signup(
  ///   username: 'testuser',
  ///   email: 'test@example.com',
  ///   password: 'Test123!',
  ///   firstName: 'Test',
  ///   lastName: 'User',
  /// );
  /// ```
  Future<User> signup({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    // 🎯 YOUR IMPLEMENTATION HERE!
    // Follow the same pattern as the login method above

    throw UnimplementedError(
      'Signup method not implemented yet!\n'
      'This is YOUR task to complete.\n'
      'Follow the pattern from the login method above.\n'
      'Check the comments for hints!',
    );
  }

  // ==========================================================================
  // LOGOUT
  // ==========================================================================

  /// Logs out the current user
  ///
  /// THE LOGOUT FLOW:
  /// ```
  /// 1. User clicks logout button in UI
  /// 2. UI calls authService.logout()
  /// 3. AuthService deletes token from secure storage
  /// 4. AuthService deletes user ID from secure storage
  /// 5. AuthService returns (no data to return)
  /// 6. UI clears user state (usually via provider)
  /// 7. UI navigates to login screen
  /// ```
  ///
  /// WHAT THIS DOES:
  /// - Clears auth token from secure storage
  /// - Clears user ID from secure storage
  /// - Effectively logs the user out
  ///
  /// NOTE: We're not calling an API endpoint here because DummyJSON
  /// doesn't have a logout endpoint. In a real app, you might call:
  /// POST /auth/logout to invalidate the token on the server.
  ///
  /// RETURNS:
  /// Nothing (Future<void>)
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// await authService.logout();
  /// print('User logged out');
  /// // Navigate to login screen
  /// ```
  ///
  /// STEP-BY-STEP BREAKDOWN:
  Future<void> logout() async {
    // STEP 1: Delete auth token
    // This is the most important step - without a token, the user can't
    // make authenticated requests
    await _storageService.deleteToken();

    // STEP 2: Delete user ID
    // Clean up any other stored user data
    await _storageService.deleteUserId();

    // You could also clear all storage:
    // await _storageService.clearAll();

    // Log for debugging
    print('User logged out successfully');

    // NOTE: In a real app, you might want to:
    // 1. Call an API endpoint to invalidate the token on server
    // 2. Clear any cached user data
    // 3. Reset any in-memory state
    // 4. Navigate to login screen (usually done in the UI layer)
  }

  // ==========================================================================
  // GET CURRENT USER
  // ==========================================================================

  /// Fetches the currently authenticated user's profile
  ///
  /// THE FLOW:
  /// ```
  /// 1. App needs current user data (e.g., to display profile)
  /// 2. App calls authService.getCurrentUser()
  /// 3. AuthService sends GET request to /auth/me
  /// 4. Server uses token to identify user
  /// 5. Server returns user data
  /// 6. AuthService converts JSON to User object
  /// 7. AuthService returns User to app
  /// ```
  ///
  /// API ENDPOINT:
  /// GET /auth/me
  ///
  /// REQUEST HEADERS:
  /// ```
  /// Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  /// ```
  ///
  /// RESPONSE (Success):
  /// ```json
  /// {
  ///   "id": 1,
  ///   "username": "emilys",
  ///   "email": "emily.johnson@x.dummyjson.com",
  ///   "firstName": "Emily",
  ///   "lastName": "Johnson",
  ///   "gender": "female",
  ///   "image": "https://dummyjson.com/icon/emilys/128"
  /// }
  /// ```
  ///
  /// WHEN TO USE THIS:
  /// - App startup (check if user is still logged in)
  /// - Profile screen (get latest user data)
  /// - After token refresh (verify new token works)
  ///
  /// RETURNS:
  /// User object with current user data
  ///
  /// THROWS:
  /// - HttpException: If request fails (token invalid, network error, etc.)
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// try {
  ///   final user = await authService.getCurrentUser();
  ///   print('Current user: ${user.username}');
  /// } catch (e) {
  ///   print('Not logged in or token expired');
  ///   // Navigate to login screen
  /// }
  /// ```
  ///
  /// STEP-BY-STEP BREAKDOWN:
  Future<User> getCurrentUser() async {
    // STEP 1: Make API call to get current user
    // We use GET because we're just fetching data
    // includeAuth defaults to true, so the token will be included
    final response = await _apiClient.get(ApiConstants.me);

    // At this point, response is a Map<String, dynamic> with the user data
    // Example: {id: 1, username: 'emilys', email: 'emily@...', ...}

    // STEP 2: Convert JSON response to User object
    final user = User.fromJson(response);

    // Log for debugging
    print('Fetched current user: ${user.username}');

    // STEP 3: Return the User object
    return user;
  }

  // ==========================================================================
  // CHECK IF LOGGED IN
  // ==========================================================================

  /// Checks if a user is currently logged in
  ///
  /// HOW IT WORKS:
  /// A user is considered logged in if they have a valid auth token
  /// stored in secure storage.
  ///
  /// WHEN TO USE THIS:
  /// - App startup (decide which screen to show)
  /// - Before navigating to protected screens
  /// - In route guards (check authentication)
  ///
  /// RETURNS:
  /// true if user has a token, false otherwise
  ///
  /// NOTE: This only checks if a token EXISTS, not if it's VALID.
  /// The token might be expired! To verify it's valid, call getCurrentUser().
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// // In app startup
  /// void initState() {
  ///   super.initState();
  ///   checkAuthStatus();
  /// }
  ///
  /// Future<void> checkAuthStatus() async {
  ///   final isLoggedIn = await authService.isLoggedIn();
  ///   if (isLoggedIn) {
  ///     // Navigate to home screen
  ///     context.go('/home');
  ///   } else {
  ///     // Navigate to login screen
  ///     context.go('/login');
  ///   }
  /// }
  /// ```
  ///
  /// ADVANCED USAGE:
  /// ```dart
  /// // Verify token is valid, not just present
  /// Future<bool> isAuthenticated() async {
  ///   final isLoggedIn = await authService.isLoggedIn();
  ///   if (!isLoggedIn) return false;
  ///
  ///   try {
  ///     // Try to fetch current user
  ///     await authService.getCurrentUser();
  ///     return true; // Token is valid
  ///   } catch (e) {
  ///     // Token is invalid or expired
  ///     await authService.logout(); // Clean up
  ///     return false;
  ///   }
  /// }
  /// ```
  Future<bool> isLoggedIn() async {
    // Check if a token exists in storage
    // This delegates to StorageService.isLoggedIn()
    return await _storageService.isLoggedIn();
  }
}

// ============================================================================
// 📚 LEARNING NOTES
// ============================================================================
//
// KEY CONCEPTS:
//
// 1. SERVICE LAYER PATTERN:
//    UI → Service → API Client → Server
//
//    BENEFITS:
//    - Separates concerns (UI handles display, Service handles logic)
//    - Reusable (multiple screens can use same service)
//    - Testable (mock the API client to test service logic)
//    - Maintainable (change logic in one place)
//
//    EXAMPLE:
//    ```dart
//    // Without service (bad - logic in UI)
//    class LoginScreen {
//      Future<void> login() async {
//        final response = await http.post(...);
//        final token = response['token'];
//        await storage.write('token', token);
//        final user = User.fromJson(response);
//        setState(() => currentUser = user);
//      }
//    }
//
//    // With service (good - logic separated)
//    class LoginScreen {
//      Future<void> login() async {
//        final user = await authService.login(username, password);
//        setState(() => currentUser = user);
//      }
//    }
//    ```
//
// 2. DEPENDENCY INJECTION:
//    We pass dependencies (ApiClient, StorageService) to the constructor
//    instead of creating them inside the class
//
//    WHY?
//    - Flexible (can swap implementations)
//    - Testable (can inject mocks)
//    - Clear dependencies (explicit in constructor)
//
//    EXAMPLE:
//    ```dart
//    // Without DI (bad)
//    class AuthService {
//      final _apiClient = ApiClient(); // Hard-coded dependency
//    }
//
//    // With DI (good)
//    class AuthService {
//      final ApiClient _apiClient; // Injected dependency
//      AuthService(this._apiClient);
//    }
//    ```
//
// 3. ASYNC/AWAIT:
//    All methods are async because they perform I/O operations:
//    - Network requests (take time)
//    - Storage operations (take time)
//
//    THE FLOW:
//    ```dart
//    print('1. Before login');
//    final user = await authService.login(...);  // Waits here
//    print('2. After login: ${user.username}');
//    ```
//
// 4. ERROR HANDLING:
//    Methods throw exceptions on failure. The calling code should catch them:
//
//    ```dart
//    try {
//      final user = await authService.login(username, password);
//      // Success path
//    } on HttpException catch (e) {
//      // Network error
//      showError(e.message);
//    } catch (e) {
//      // Unexpected error
//      showError('An unexpected error occurred');
//    }
//    ```
//
// 5. includeAuth PARAMETER:
//    Some endpoints need authentication, others don't:
//
//    NO AUTH (includeAuth: false):
//    - Login (not logged in yet!)
//    - Signup (creating account)
//    - Password reset (forgot password)
//
//    WITH AUTH (includeAuth: true, default):
//    - Get current user (need to identify who's asking)
//    - Update profile (need to verify it's you)
//    - Add to cart (need to know whose cart)
//
// 6. TOKEN MANAGEMENT:
//    After successful login:
//    1. Server returns user data + token
//    2. Service extracts token from response
//    3. Service saves token to secure storage
//    4. Service converts response to User object
//    5. Service returns User to caller
//
//    For subsequent requests:
//    1. ApiClient reads token from storage
//    2. ApiClient adds token to Authorization header
//    3. Server validates token
//    4. Server processes request
//
// 7. USER OBJECT FLOW:
//    JSON (from API) → User.fromJson() → User object → return to caller
//
//    Example:
//    ```dart
//    // JSON from API
//    final json = {'id': 1, 'username': 'john', ...};
//
//    // Convert to User object
//    final user = User.fromJson(json);
//
//    // Now you can access fields
//    print(user.id);       // 1
//    print(user.username); // john
//    ```
//
// ============================================================================
// 🎯 TESTING YOUR SERVICE
// ============================================================================
//
// TEST LOGIN:
// ```dart
// // Valid credentials for DummyJSON:
// final user = await authService.login('emilys', 'emilyspass');
// print('Logged in: ${user.username}');
// ```
//
// TEST LOGOUT:
// ```dart
// await authService.logout();
// final isLoggedIn = await authService.isLoggedIn();
// print('Still logged in? $isLoggedIn'); // Should be false
// ```
//
// TEST GET CURRENT USER:
// ```dart
// // Must be logged in first
// final user = await authService.getCurrentUser();
// print('Current user: ${user.username}');
// ```
//
// ============================================================================
// 🎯 YOUR TASK
// ============================================================================
//
// IMPLEMENT THE SIGNUP METHOD!
//
// Follow the same pattern as login:
// 1. Make API call with _apiClient.post()
// 2. Use ApiConstants.register endpoint
// 3. Include all parameters in body
// 4. Set includeAuth: false
// 5. Convert response to User with User.fromJson()
// 6. Return the User object
//
// TIP: Look at the login method and replicate its structure!
//
// ============================================================================
