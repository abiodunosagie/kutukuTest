// ============================================================================
// LOGIN SCREEN WITH API INTEGRATION
// ============================================================================
// This is a COMPLETE EXAMPLE of integrating API with UI using Riverpod.
//
// WHAT YOU'LL LEARN:
// 1. How to convert StatefulWidget to ConsumerStatefulWidget
// 2. How to watch providers for state changes
// 3. How to call provider methods
// 4. How to listen for side effects (navigation, snackbars)
// 5. How to handle loading, success, and error states
// 6. How to use real API authentication
//
// YOUR TASK:
// Study this file carefully, then implement signup screen following
// the same pattern!
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Step 1: Import Riverpod
import 'package:go_router/go_router.dart';
import 'package:kutuku/providers/auth_provider.dart'; // Step 2: Import auth provider
import 'package:kutuku/router/app_router.dart';
import 'package:kutuku/widget/forget_bottom_sheet.dart';
import 'package:kutuku/widget/new_password.dart';

// ============================================================================
// STEP 1: CHANGE FROM StatefulWidget TO ConsumerStatefulWidget
// ============================================================================
//
// BEFORE (without Riverpod):
// class LoginScreen extends StatefulWidget { ... }
//
// AFTER (with Riverpod):
// class LoginScreen extends ConsumerStatefulWidget { ... }
//
// WHY?
// ConsumerStatefulWidget gives you access to "ref" which allows you to:
// - Watch providers (ref.watch)
// - Read providers (ref.read)
// - Listen to providers (ref.listen)
//
// Without ConsumerStatefulWidget, you can't access providers!

class LoginScreenWithApi extends ConsumerStatefulWidget {
  const LoginScreenWithApi({super.key});

  @override
  ConsumerState<LoginScreenWithApi> createState() => _LoginScreenWithApiState();
  //     ^^^^^^^^^^^^
  // Note: Changed from State<LoginScreen> to ConsumerState<LoginScreen>
  // This is REQUIRED for Riverpod to work in stateful widgets
}

// ============================================================================
// STEP 2: CHANGE FROM State TO ConsumerState
// ============================================================================
//
// BEFORE:
// class _LoginScreenState extends State<LoginScreen> { ... }
//
// AFTER:
// class _LoginScreenState extends ConsumerState<LoginScreen> { ... }
//
// This gives the State class access to "ref"

class _LoginScreenWithApiState extends ConsumerState<LoginScreenWithApi> {
  // ==========================================================================
  // PROPERTIES (Form Controllers)
  // ==========================================================================
  // These remain the same - we still need controllers for text fields

  /// Controller for email/username input field
  /// Holds the text value the user types
  final TextEditingController _usernameController = TextEditingController();

  /// Controller for password input field
  final TextEditingController _passwordController = TextEditingController();

  /// Global key for form validation
  /// Allows us to validate all form fields at once
  final _formKey = GlobalKey<FormState>();

  /// Whether password is hidden or visible
  /// true = hidden (●●●●), false = visible (abc123)
  bool _obscurePassword = true;

  /// Whether form has been submitted
  /// Used to show validation errors only after user tries to submit
  bool _submitted = false;

  // ==========================================================================
  // LIFECYCLE METHODS
  // ==========================================================================

  @override
  void dispose() {
    // IMPORTANT: Always dispose controllers to prevent memory leaks!
    // This is called when the widget is removed from the tree
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // STEP 3: FORM SUBMISSION METHOD (WITH API INTEGRATION)
  // ==========================================================================
  //
  // THIS IS THE KEY METHOD!
  // This is where the magic happens - we call the API through our provider.
  //
  // FLOW:
  // 1. User enters username & password
  // 2. User clicks "SIGN IN" button
  // 3. This method is called
  // 4. We validate the form
  // 5. We call the auth provider's login method
  // 6. Provider handles the API call
  // 7. State updates automatically
  // 8. UI rebuilds based on new state

  void _submitLoginForm() {
    // STEP 3.1: Mark form as submitted
    // This enables validation error messages
    setState(() {
      _submitted = true;
    });

    // STEP 3.2: Validate form fields
    // _formKey.currentState!.validate() calls all validator functions
    // Returns true if all validations pass, false otherwise
    if (!_formKey.currentState!.validate()) {
      // Validation failed - show error messages
      // The validator functions already display errors, so we just return
      print('Form validation failed');
      return;
    }

    // STEP 3.3: Get input values
    // Extract text from controllers
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    // STEP 3.4: Call the auth provider's login method
    //
    // THIS IS THE MOST IMPORTANT LINE!
    // ref.read(authStateProvider.notifier) gets the AuthNotifier instance
    // .login(...) calls the login method we defined in auth_provider.dart
    //
    // WHY ref.read?
    // - ref.read: One-time access, doesn't listen for changes
    // - Use ref.read in callbacks (button press, etc.)
    // - Use ref.watch in build methods
    //
    // WHAT HAPPENS:
    // 1. AuthNotifier.login() is called
    // 2. State changes to AsyncValue.loading()
    // 3. API request is made
    // 4. State changes to AsyncValue.data(user) or AsyncValue.error(...)
    // 5. UI rebuilds automatically (via ref.watch in build method)
    // 6. ref.listen in build method handles side effects (navigation)
    ref.read(authStateProvider.notifier).login(username, password);

    // NOTE: We DON'T navigate here!
    // Navigation happens in ref.listen (see build method)
    // This separates concerns:
    // - This method: Trigger action
    // - ref.listen: Handle side effects
  }

  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================

  /// Toggles password visibility
  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  // ==========================================================================
  // VALIDATION METHODS
  // ==========================================================================

  /// Validates email/username input
  ///
  /// VALIDATION RULES:
  /// 1. Field is not empty
  /// 2. Valid email format OR valid username
  ///
  /// RETURNS:
  /// - null: Field is valid
  /// - String: Error message
  String? _validateUsername(String? value) {
    // Don't show errors until form is submitted
    if (!_submitted) return null;

    // Check if empty
    if (value == null || value.isEmpty) {
      return "Username or email is required";
    }

    // For DummyJSON API, accept any non-empty value
    // (Real app would validate email format if requiring email)

    return null; // Valid!
  }

  /// Validates password input
  ///
  /// VALIDATION RULES:
  /// 1. Field is not empty
  /// 2. At least 8 characters (basic security)
  ///
  /// RETURNS:
  /// - null: Field is valid
  /// - String: Error message
  String? _validatePassword(String? value) {
    // Don't show errors until form is submitted
    if (!_submitted) return null;

    // Check if empty
    if (value == null || value.isEmpty) {
      return "Password is required";
    }

    // Check minimum length
    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }

    return null; // Valid!
  }

  // ==========================================================================
  // STEP 4: BUILD METHOD (WITH PROVIDER WATCHING)
  // ==========================================================================
  //
  // THIS IS WHERE THE UI CONNECTS TO STATE!
  //
  // KEY CONCEPTS:
  // 1. ref.watch: Listens to provider, rebuilds when state changes
  // 2. ref.listen: Runs side effects (navigation, snackbars) on state changes
  // 3. AsyncValue.when: Handles loading, data, error states easily

  @override
  Widget build(BuildContext context) {
    // ========================================================================
    // STEP 4.1: WATCH THE AUTH STATE PROVIDER
    // ========================================================================
    //
    // ref.watch(authStateProvider) subscribes to auth state changes
    // Whenever authState changes, this widget rebuilds automatically
    //
    // authState is of type AsyncValue<User?>:
    // - AsyncValue.loading(): Login in progress
    // - AsyncValue.data(user): Login succeeded, user is logged in
    // - AsyncValue.data(null): Not logged in
    // - AsyncValue.error(error, stack): Login failed

    final authState = ref.watch(authStateProvider);
    //    ^^^^^^^^^
    // This widget now automatically rebuilds when auth state changes!

    // ========================================================================
    // STEP 4.2: LISTEN FOR SIDE EFFECTS
    // ========================================================================
    //
    // ref.listen runs side effects when state changes
    // It does NOT rebuild the widget (unlike ref.watch)
    //
    // USE CASES:
    // - Show snackbars
    // - Navigate to different screens
    // - Show dialogs
    // - Trigger animations
    //
    // DIFFERENCE FROM ref.watch:
    // - ref.watch: Rebuilds widget when state changes
    // - ref.listen: Runs callback when state changes (no rebuild)

    ref.listen<AsyncValue>(
      authStateProvider, // The provider to listen to
      (previous, next) {
        // This callback is called whenever authState changes
        // previous: The old state
        // next: The new state

        // Use .when to handle different states
        next.when(
          // ====================================================================
          // SUCCESS STATE
          // ====================================================================
          // This runs when state becomes AsyncValue.data(...)
          data: (user) {
            if (user != null) {
              // User logged in successfully!
              // Navigate to home screen

              print('Login successful! User: ${user.username}');

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome back, ${user.username}!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );

              // Navigate to home screen
              // Replace current route so user can't go back to login
              context.goNamed(AppRouter.home);
            }
            // If user is null, we're in logged-out state (no action needed)
          },

          // ====================================================================
          // ERROR STATE
          // ====================================================================
          // This runs when state becomes AsyncValue.error(...)
          error: (error, stackTrace) {
            // Login failed!
            // Show error message to user

            print('Login failed: $error');

            // Extract user-friendly error message
            String errorMessage = 'Login failed';
            if (error.toString().contains('Invalid credentials')) {
              errorMessage = 'Invalid username or password';
            } else if (error.toString().contains('No internet')) {
              errorMessage = 'No internet connection';
            } else {
              errorMessage = 'Login failed. Please try again.';
            }

            // Show error snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          },

          // ====================================================================
          // LOADING STATE
          // ====================================================================
          // This runs when state becomes AsyncValue.loading()
          // We don't need to do anything here (loading indicator is shown in UI)
          loading: () {
            print('Login in progress...');
            // Could show a loading dialog here if desired
          },
        );
      },
    );

    // ========================================================================
    // STEP 4.3: BUILD THE UI
    // ========================================================================

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          // Dismiss keyboard when tapping outside text fields
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================================
                  // HEADER
                  // ============================================================
                  const Text(
                    'Login Account',
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Please login with your account',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ============================================================
                  // API TEST CREDENTIALS BOX
                  // ============================================================
                  // This helps you test the API integration!
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🔐 Test Credentials (DummyJSON)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Username: emilys',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          'Password: emilyspass',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Auto-fill test credentials
                            _usernameController.text = 'emilys';
                            _passwordController.text = 'emilyspass';
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Auto-fill'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ============================================================
                  // LOGIN FORM
                  // ============================================================
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ======================================================
                        // USERNAME FIELD
                        // ======================================================
                        const Text(
                          'Username or Email',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _usernameController,
                          validator: _validateUsername,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Enter your username or email',
                            filled: true,
                            fillColor: Colors.grey[200],
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: Colors.indigo,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.indigo,
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ======================================================
                        // PASSWORD FIELD
                        // ======================================================
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: _validatePassword,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            filled: true,
                            fillColor: Colors.grey[200],
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Colors.indigo,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.indigo,
                              ),
                              onPressed: _togglePasswordVisibility,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.indigo,
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ======================================================
                        // FORGOT PASSWORD
                        // ======================================================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    child: ForgetBottomSheet(
                                      onContinue: () {
                                        Navigator.pop(context);
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                            ),
                                            child: NewPassword(
                                              onContinue: () {
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Password reset successfully!',
                                                    ),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.indigo,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        // ======================================================
                        // SIGN IN BUTTON (WITH LOADING STATE)
                        // ======================================================
                        //
                        // THIS IS WHERE WE USE THE AUTH STATE!
                        // We use authState.isLoading to:
                        // 1. Show loading indicator in button
                        // 2. Disable button while loading
                        //
                        // BEFORE: Button always enabled
                        // AFTER: Button disabled while loading API request

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.indigo,
                              // Disable button while loading
                              disabledBackgroundColor: Colors.grey,
                            ),
                            // ================================================
                            // DISABLE BUTTON WHILE LOADING
                            // ================================================
                            // If loading, onPressed = null (disabled)
                            // If not loading, onPressed = _submitLoginForm
                            onPressed: authState.isLoading
                                ? null
                                : _submitLoginForm,
                            //         ^^^^^^^^^^^^^^^^^^^
                            // This prevents multiple simultaneous login requests!

                            // ================================================
                            // SHOW LOADING INDICATOR OR TEXT
                            // ================================================
                            child: authState.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'SIGN IN',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ============================================================
                  // DIVIDER
                  // ============================================================
                  const Center(
                    child: Text(
                      'or using other methods',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ============================================================
                  // SOCIAL LOGIN BUTTONS (UI ONLY)
                  // ============================================================
                  // These are not implemented in this tutorial
                  // They're here for UI completeness
                  _buildSocialButton(
                    'assets/logo/googleicon.png',
                    'Sign in with Google',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Google Sign-In not implemented'),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  _buildSocialButton(
                    'assets/logo/faceicon.png',
                    'Sign in with Facebook',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Facebook Sign-In not implemented'),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // ============================================================
                  // SIGN UP LINK
                  // ============================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(fontSize: 15),
                      ),
                      TextButton(
                        onPressed: () {
                          context.goNamed(AppRouter.signup);
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // HELPER WIDGET: SOCIAL BUTTON
  // ==========================================================================

  Widget _buildSocialButton(
    String iconPath,
    String text,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              height: 30,
              width: 30,
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 📚 RECAP: WHAT WE DID
// ============================================================================
//
// 1. Changed StatefulWidget → ConsumerStatefulWidget
//    - Gives us access to "ref"
//
// 2. Changed State → ConsumerState
//    - Required for stateful widgets with Riverpod
//
// 3. Used ref.watch(authStateProvider)
//    - Subscribes to auth state
//    - Widget rebuilds when state changes
//
// 4. Used ref.listen(authStateProvider, ...)
//    - Runs side effects (navigation, snackbars)
//    - Doesn't rebuild widget
//
// 5. Used ref.read(authStateProvider.notifier).login(...)
//    - Calls the login method in AuthNotifier
//    - Triggers API request
//
// 6. Used authState.isLoading
//    - Shows loading indicator
//    - Disables button during API call
//
// 7. Handled success/error in ref.listen
//    - Navigate on success
//    - Show snackbar on error
//
// ============================================================================
// 🎯 YOUR TASK
// ============================================================================
//
// NOW IMPLEMENT SIGNUP SCREEN!
//
// Follow these steps:
// 1. Copy this file structure
// 2. Change to signup fields (username, email, password, confirm password)
// 3. Call ref.read(authStateProvider.notifier).signup(...)
// 4. Handle the response
//
// HINT: It's almost identical to this file!
// Just change the fields and the method you call.
//
// ============================================================================
// 🐛 COMMON ISSUES & SOLUTIONS
// ============================================================================
//
// ISSUE: "No ProviderScope found"
// SOLUTION: Make sure main.dart wraps App with ProviderScope
//
// ISSUE: "Cannot use 'ref' outside of a Consumer"
// SOLUTION: Change StatefulWidget → ConsumerStatefulWidget
//
// ISSUE: Button stays loading forever
// SOLUTION: Make sure your service updates state on both success AND error
//
// ISSUE: Navigation doesn't happen
// SOLUTION: Check ref.listen is in build method (not initState!)
//
// ISSUE: Widget rebuilds too much
// SOLUTION: Use ref.read in callbacks, ref.watch only in build
//
// ============================================================================
