// ============================================================================
// AUTHENTICATION PROVIDER
// ============================================================================
// This file contains Riverpod providers for authentication state management.
//
// WHAT IS A PROVIDER?
// Think of a provider as a "smart box" that:
// 1. Holds data (state)
// 2. Notifies widgets when data changes
// 3. Automatically rebuilds UI when needed
// 4. Can be accessed from anywhere in your app
//
// WHY RIVERPOD?
// - Compile-time safety (catches errors before running)
// - No context needed (access from anywhere)
// - Better performance (only rebuilds what changed)
// - Easy testing (mock providers easily)
// - Built-in async support (loading, error states)
//
// ARCHITECTURE FLOW:
// ```
// UI Widget
//   ↓ (watches)
// Provider
//   ↓ (uses)
// Service
//   ↓ (calls)
// API Client
//   ↓ (requests)
// Server
// ```
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kutuku/models/user.dart';
import 'package:kutuku/services/api_client.dart';
import 'package:kutuku/services/auth_service.dart';
import 'package:kutuku/utils/api_constants.dart';
import 'package:kutuku/utils/storage_service.dart';

// ============================================================================
// FOUNDATIONAL PROVIDERS
// ============================================================================
// These providers create instances of services.
// They're at the bottom of the dependency chain.

/// Provider for StorageService
///
/// WHAT IT DOES:
/// Creates a single instance of StorageService that's reused throughout the app
///
/// PROVIDER TYPE: Provider<T>
/// - Provider: Creates a simple, immutable value
/// - <StorageService>: The type of value it provides
///
/// LIFECYCLE:
/// Created once when first accessed, never disposed (singleton pattern)
///
/// WHY FINAL?
/// Providers should never be reassigned (they're global constants)
///
/// EXAMPLE USAGE:
/// ```dart
/// // In a widget
/// final storage = ref.watch(storageServiceProvider);
/// final token = await storage.getToken();
/// ```
final storageServiceProvider = Provider<StorageService>((ref) {
  // This function is called once when the provider is first accessed
  // The return value is cached and reused for all subsequent accesses

  return StorageService();
  // Creates and returns a new StorageService instance
});

/// Provider for ApiClient
///
/// WHAT IT DOES:
/// Creates a single instance of ApiClient, injecting StorageService dependency
///
/// PROVIDER TYPE: Provider<T>
///
/// DEPENDENCY:
/// This provider DEPENDS on storageServiceProvider
/// It uses ref.watch to access the storage service
///
/// WHY ref.watch?
/// ref.watch creates a dependency relationship:
/// - If storageServiceProvider changes, this provider rebuilds
/// - But since storageServiceProvider is a simple Provider, it never changes
///
/// EXAMPLE USAGE:
/// ```dart
/// final apiClient = ref.watch(apiClientProvider);
/// final data = await apiClient.get('/products');
/// ```
final apiClientProvider = Provider<ApiClient>((ref) {
  // Get the storage service from its provider
  final storage = ref.watch(storageServiceProvider);

  // Create and return ApiClient, passing required dependencies
  return ApiClient(
    ApiConstants.baseUrl, // Base URL for all requests
    storage, // Storage service for token management
  );
});

/// Provider for AuthService
///
/// WHAT IT DOES:
/// Creates a single instance of AuthService, injecting dependencies
///
/// PROVIDER TYPE: Provider<T>
///
/// DEPENDENCIES:
/// - apiClientProvider: For making HTTP requests
/// - storageServiceProvider: For managing tokens
///
/// WHY TWO DEPENDENCIES?
/// AuthService needs both:
/// - ApiClient to call the server
/// - StorageService to save/retrieve tokens
///
/// EXAMPLE USAGE:
/// ```dart
/// final authService = ref.watch(authServiceProvider);
/// final user = await authService.login('username', 'password');
/// ```
final authServiceProvider = Provider<AuthService>((ref) {
  // Get dependencies from their providers
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(storageServiceProvider);

  // Create and return AuthService
  return AuthService(apiClient, storage);
});

// ============================================================================
// AUTH STATE PROVIDER
// ============================================================================
// This is the main provider that UI widgets will watch.
// It manages the authentication state of the app.

/// Provider for authentication state
///
/// WHAT IT DOES:
/// Manages the current user state (logged in, logged out, loading, error)
///
/// PROVIDER TYPE: StateNotifierProvider<Notifier, State>
/// - StateNotifierProvider: Provider for mutable state
/// - AuthNotifier: The class that manages state
/// - AsyncValue<User?>: The state type
///
/// STATE TYPE: AsyncValue<User?>
/// - AsyncValue: Represents async states (loading, data, error)
/// - User?: The data type (User or null if not logged in)
///
/// WHY AsyncValue?
/// API calls are asynchronous. AsyncValue provides three states:
/// 1. loading: Request in progress
/// 2. data: Request succeeded, contains result
/// 3. error: Request failed, contains error
///
/// EXAMPLE USAGE:
/// ```dart
/// // In a widget
/// final authState = ref.watch(authStateProvider);
///
/// authState.when(
///   loading: () => CircularProgressIndicator(),
///   data: (user) => user != null
///       ? Text('Hello ${user.username}')
///       : Text('Not logged in'),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
///
/// CALLING METHODS:
/// ```dart
/// // Login
/// ref.read(authStateProvider.notifier).login('username', 'password');
///
/// // Logout
/// ref.read(authStateProvider.notifier).logout();
/// ```
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  // Get the auth service dependency
  final authService = ref.watch(authServiceProvider);

  // Create and return the AuthNotifier
  return AuthNotifier(authService);
});

// ============================================================================
// AUTH NOTIFIER
// ============================================================================
// This class contains the business logic for authentication state management.

/// State manager for authentication
///
/// WHAT IT DOES:
/// - Holds the current user state
/// - Provides methods to login, logout, etc.
/// - Notifies listeners when state changes
///
/// EXTENDS: StateNotifier<AsyncValue<User?>>
/// - StateNotifier: Base class for managing state
/// - <AsyncValue<User?>>: The type of state it manages
///
/// HOW IT WORKS:
/// 1. UI calls a method (e.g., login())
/// 2. Method updates state to loading
/// 3. Method calls service to perform action
/// 4. Method updates state to data or error based on result
/// 5. Riverpod notifies all watching widgets
/// 6. Widgets rebuild with new state
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  // ==========================================================================
  // PROPERTIES
  // ==========================================================================

  /// The authentication service
  /// Used to perform actual auth operations (login, logout, etc.)
  final AuthService _authService;

  // ==========================================================================
  // CONSTRUCTOR
  // ==========================================================================

  /// Creates an AuthNotifier
  ///
  /// PARAMETERS:
  /// - _authService: The service for auth operations
  ///
  /// INITIAL STATE:
  /// AsyncValue.data(null)
  /// - data: Not loading, no error
  /// - null: No user logged in
  ///
  /// WHY super()?
  /// Calls StateNotifier's constructor with initial state
  ///
  /// STATE TRANSITION EXAMPLE:
  /// ```
  /// Initial:  AsyncValue.data(null)          // Not logged in
  ///    ↓ login() called
  /// Loading:  AsyncValue.loading()           // Logging in...
  ///    ↓ login succeeds
  /// Success:  AsyncValue.data(user)          // Logged in!
  ///    ↓ login fails
  /// Error:    AsyncValue.error(error, stack) // Login failed!
  /// ```
  AuthNotifier(this._authService) : super(const AsyncValue.data(null)) {
    // The constructor body
    // We could initialize other things here if needed

    // Note: We DON'T call checkAuthStatus here because:
    // 1. Constructors can't be async
    // 2. We want explicit control over when to check
    // Instead, call it from main() or app initialization
  }

  // ==========================================================================
  // LOGIN METHOD
  // ==========================================================================

  /// Logs in a user with username and password
  ///
  /// THE FLOW:
  /// ```
  /// 1. UI calls ref.read(authStateProvider.notifier).login(...)
  /// 2. This method sets state to loading
  /// 3. This method calls _authService.login(...)
  /// 4. Service makes API request
  /// 5. API returns user data + token
  /// 6. Service saves token and returns User
  /// 7. This method sets state to data(user)
  /// 8. Riverpod notifies all watchers
  /// 9. UI rebuilds with logged-in user
  /// ```
  ///
  /// STATE CHANGES:
  /// ```
  /// Before: AsyncValue.data(null)     // Not logged in
  /// During: AsyncValue.loading()      // Logging in...
  /// Success: AsyncValue.data(user)    // Logged in!
  /// Error: AsyncValue.error(e, stack) // Failed!
  /// ```
  ///
  /// PARAMETERS:
  /// - username: User's username or email
  /// - password: User's password
  ///
  /// RETURNS:
  /// Nothing (void) - state is updated instead
  ///
  /// SIDE EFFECTS:
  /// - Updates state
  /// - Saves auth token to storage (via service)
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// // In a widget
  /// onPressed: () {
  ///   ref.read(authStateProvider.notifier).login(
  ///     _usernameController.text,
  ///     _passwordController.text,
  ///   );
  /// }
  /// ```
  ///
  /// STEP-BY-STEP BREAKDOWN:
  Future<void> login(String username, String password) async {
    // STEP 1: Set state to loading
    // This tells the UI to show a loading indicator
    // All watching widgets will rebuild with the loading state
    state = const AsyncValue.loading();

    // Why const?
    // AsyncValue.loading() has no data, so it can be a compile-time constant
    // This is more efficient than creating a new object

    // At this point:
    // - Login button should be disabled
    // - Loading indicator should be visible
    // - Error message (if any) should be hidden

    // STEP 2: Try to login
    try {
      // Call the auth service to perform the actual login
      // This is an async operation that:
      // 1. Makes HTTP request to server
      // 2. Saves auth token to secure storage
      // 3. Returns User object
      //
      // await waits for the operation to complete before continuing
      final user = await _authService.login(username, password);

      // If we reach this line, login was successful!
      // user is a User object with all user data

      // STEP 3: Set state to success with user data
      // This tells the UI that login succeeded and provides the user data
      state = AsyncValue.data(user);

      // At this point:
      // - authState.value will be the User object
      // - authState.hasValue will be true
      // - authState.isLoading will be false
      // - UI will rebuild and navigate to home screen

      // Note: We don't need to manually navigate here
      // The UI layer handles navigation by listening to state changes
      // (using ref.listen)
    } catch (error, stackTrace) {
      // If we reach this block, login failed!
      // error could be:
      // - HttpException (API error)
      // - SocketException (no internet)
      // - FormatException (JSON parse error)
      // - Any other exception

      // STEP 4: Set state to error
      // This tells the UI that login failed and provides error details
      state = AsyncValue.error(error, stackTrace);

      // At this point:
      // - authState.hasError will be true
      // - authState.isLoading will be false
      // - authState.error will contain the error
      // - UI will rebuild and show error message

      // Note: We don't need to show error message here
      // The UI layer handles error display by watching the state
      // or using ref.listen for side effects (snackbars, dialogs)

      // stackTrace is useful for debugging
      // In production, you might want to log this to an error tracking service
      // (like Sentry, Firebase Crashlytics, etc.)
    }

    // After this method completes, the state has been updated to either:
    // - AsyncValue.data(user) on success
    // - AsyncValue.error(error, stackTrace) on failure
    //
    // Riverpod automatically notifies all widgets watching authStateProvider
    // Those widgets rebuild with the new state
  }

  // ==========================================================================
  // LOGOUT METHOD
  // ==========================================================================

  /// Logs out the current user
  ///
  /// THE FLOW:
  /// ```
  /// 1. UI calls ref.read(authStateProvider.notifier).logout()
  /// 2. This method calls _authService.logout()
  /// 3. Service deletes token from storage
  /// 4. This method sets state to data(null)
  /// 5. Riverpod notifies all watchers
  /// 6. UI rebuilds showing logged-out state
  /// 7. UI navigates to login screen
  /// ```
  ///
  /// STATE CHANGES:
  /// ```
  /// Before: AsyncValue.data(user) // Logged in
  /// After: AsyncValue.data(null)  // Logged out
  /// ```
  ///
  /// WHY NOT LOADING STATE?
  /// Logout is usually fast (just deleting from storage)
  /// No need to show loading indicator
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// // In a widget (logout button)
  /// onPressed: () async {
  ///   await ref.read(authStateProvider.notifier).logout();
  ///   context.go('/login');
  /// }
  /// ```
  Future<void> logout() async {
    // Call the auth service to perform logout
    // This deletes the token from secure storage
    await _authService.logout();

    // Set state to logged out (null user)
    // This tells the UI that no user is logged in
    state = const AsyncValue.data(null);

    // At this point:
    // - authState.value will be null
    // - authState.hasValue will be true (value is null, but it has a value!)
    // - UI will rebuild showing logged-out state
    // - UI should navigate to login screen
  }

  // ==========================================================================
  // CHECK AUTH STATUS
  // ==========================================================================

  /// Checks if user is logged in (useful for app startup)
  ///
  /// THE FLOW:
  /// ```
  /// 1. App starts
  /// 2. App calls checkAuthStatus()
  /// 3. This method checks if token exists
  /// 4. If token exists, fetch current user
  /// 5. Update state with user or null
  /// 6. UI shows appropriate screen (home or login)
  /// ```
  ///
  /// WHEN TO CALL:
  /// - App startup (in main() or app initialization)
  /// - After token refresh
  /// - After deep link navigation
  ///
  /// STATE CHANGES:
  /// ```
  /// Initial:  AsyncValue.data(null)  // Unknown state
  ///    ↓ checking...
  /// Loading:  AsyncValue.loading()   // Checking...
  ///    ↓ if token exists and valid
  /// Success:  AsyncValue.data(user)  // Logged in!
  ///    ↓ if no token or invalid
  /// Success:  AsyncValue.data(null)  // Not logged in
  /// ```
  ///
  /// EXAMPLE USAGE:
  /// ```dart
  /// // In main.dart or app initialization
  /// void main() {
  ///   runApp(
  ///     ProviderScope(
  ///       child: MyApp(),
  ///     ),
  ///   );
  /// }
  ///
  /// class MyApp extends ConsumerStatefulWidget {
  ///   @override
  ///   _MyAppState createState() => _MyAppState();
  /// }
  ///
  /// class _MyAppState extends ConsumerState<MyApp> {
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     // Check auth status when app starts
  ///     Future.microtask(() {
  ///       ref.read(authStateProvider.notifier).checkAuthStatus();
  ///     });
  ///   }
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final authState = ref.watch(authStateProvider);
  ///
  ///     return authState.when(
  ///       loading: () => LoadingScreen(),
  ///       data: (user) => user != null ? HomeScreen() : LoginScreen(),
  ///       error: (_, __) => LoginScreen(),
  ///     );
  ///   }
  /// }
  /// ```
  Future<void> checkAuthStatus() async {
    // Set state to loading while checking
    state = const AsyncValue.loading();

    try {
      // Check if user is logged in (has a token)
      final isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        // Token exists! Try to fetch current user to verify it's valid
        try {
          final user = await _authService.getCurrentUser();

          // Token is valid, set state with user
          state = AsyncValue.data(user);
        } catch (e) {
          // Token exists but is invalid (expired, revoked, etc.)
          // Log out and set state to null
          await _authService.logout();
          state = const AsyncValue.data(null);
        }
      } else {
        // No token, user is not logged in
        state = const AsyncValue.data(null);
      }
    } catch (error, stackTrace) {
      // Unexpected error during check
      // Assume not logged in
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// ============================================================================
// 📚 LEARNING NOTES
// ============================================================================
//
// KEY CONCEPTS:
//
// 1. PROVIDER TYPES:
//    - Provider<T>: Simple, immutable value (never changes)
//    - StateProvider<T>: Simple, mutable value
//    - StateNotifierProvider<N, S>: Complex, mutable state with logic
//
//    Use Provider for services (they don't change)
//    Use StateNotifierProvider for app state (login status, cart, etc.)
//
// 2. ref.watch vs ref.read:
//    - ref.watch: Creates dependency, rebuilds when provider changes
//    - ref.read: One-time read, doesn't create dependency
//
//    EXAMPLE:
//    ```dart
//    // In build method (rebuilds when auth changes)
//    final authState = ref.watch(authStateProvider);
//
//    // In button callback (just call a method, don't watch)
//    onPressed: () {
//      ref.read(authStateProvider.notifier).login(...);
//    }
//    ```
//
// 3. AsyncValue STATES:
//    - AsyncValue.loading(): Operation in progress
//    - AsyncValue.data(value): Operation succeeded
//    - AsyncValue.error(error, stack): Operation failed
//
//    CHECK STATES:
//    ```dart
//    final authState = ref.watch(authStateProvider);
//
//    if (authState.isLoading) {
//      // Show loading
//    } else if (authState.hasError) {
//      // Show error
//    } else if (authState.hasValue) {
//      // Show data
//      final user = authState.value; // User?
//    }
//    ```
//
//    OR USE .when:
//    ```dart
//    authState.when(
//      loading: () => CircularProgressIndicator(),
//      data: (user) => user != null ? HomeScreen() : LoginScreen(),
//      error: (error, stack) => ErrorWidget(error: error),
//    );
//    ```
//
// 4. STATE UPDATES:
//    NEVER modify state directly:
//    ```dart
//    state.value = newUser; // ❌ WRONG!
//    ```
//
//    ALWAYS assign a new value:
//    ```dart
//    state = AsyncValue.data(newUser); // ✅ CORRECT!
//    ```
//
// 5. WATCHING PROVIDERS:
//    ```dart
//    // In a ConsumerWidget
//    @override
//    Widget build(BuildContext context, WidgetRef ref) {
//      final authState = ref.watch(authStateProvider);
//
//      // Widget automatically rebuilds when authState changes
//      return authState.when(
//        loading: () => LoadingScreen(),
//        data: (user) => HomeScreen(user: user),
//        error: (error, stack) => ErrorScreen(error: error),
//      );
//    }
//    ```
//
// 6. LISTENING FOR SIDE EFFECTS:
//    ```dart
//    // In a ConsumerWidget
//    @override
//    Widget build(BuildContext context, WidgetRef ref) {
//      // Listen for state changes to show snackbars, navigate, etc.
//      ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
//        next.when(
//          data: (user) {
//            if (user != null) {
//              // User logged in, navigate to home
//              context.go('/home');
//            }
//          },
//          error: (error, stackTrace) {
//            // Show error snackbar
//            ScaffoldMessenger.of(context).showSnackBar(
//              SnackBar(content: Text('Error: $error')),
//            );
//          },
//          loading: () {}, // Do nothing while loading
//        );
//      });
//
//      // Build UI
//      return LoginScreen();
//    }
//    ```
//
// 7. CONSUMER WIDGETS:
//    To use providers in widgets, you have two options:
//
//    OPTION 1: ConsumerWidget (stateless)
//    ```dart
//    class MyWidget extends ConsumerWidget {
//      @override
//      Widget build(BuildContext context, WidgetRef ref) {
//        final authState = ref.watch(authStateProvider);
//        return Text('User: ${authState.value?.username}');
//      }
//    }
//    ```
//
//    OPTION 2: ConsumerStatefulWidget (stateful)
//    ```dart
//    class MyWidget extends ConsumerStatefulWidget {
//      @override
//      _MyWidgetState createState() => _MyWidgetState();
//    }
//
//    class _MyWidgetState extends ConsumerState<MyWidget> {
//      @override
//      Widget build(BuildContext context) {
//        final authState = ref.watch(authStateProvider);
//        return Text('User: ${authState.value?.username}');
//      }
//    }
//    ```
//
// ============================================================================
// 🎯 NEXT STEPS
// ============================================================================
//
// Now you'll:
// 1. Update login screen to use this provider
// 2. Watch the state to show loading/error/success
// 3. Call login method when button is pressed
// 4. Listen for state changes to navigate
//
// ============================================================================
