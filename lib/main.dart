// ============================================================================
// MAIN ENTRY POINT
// ============================================================================
// This is where your Flutter app starts!
//
// CRITICAL CHANGE:
// We wrap the app with ProviderScope to enable Riverpod state management.
// Without this, providers won't work!
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:kutuku/app.dart';

/// Entry point of the application
///
/// WHAT HAPPENS HERE:
/// 1. Flutter calls main() when app starts
/// 2. runApp() inflates the widget tree
/// 3. ProviderScope enables Riverpod throughout the app
/// 4. App widget is the root of our application
///
/// WHY ProviderScope?
/// Riverpod requires ProviderScope at the root to:
/// - Track all providers
/// - Manage provider lifecycle
/// - Enable provider access via ref
///
/// STRUCTURE:
/// ```
/// ProviderScope          ← Enables Riverpod
///   └── App             ← Your app's root widget
///       └── MaterialApp ← Material Design wrapper
///           └── Screens ← Your app's screens
/// ```
void main() {
  // Run the app with Riverpod support
  runApp(
    // ProviderScope is REQUIRED for Riverpod to work
    // It wraps your entire app and manages all providers
    const ProviderScope(
      // Your app's root widget
      child: App(),
    ),
  );
}

// ============================================================================
// 📚 LEARNING NOTES
// ============================================================================
//
// KEY CONCEPTS:
//
// 1. PROVIDERSCOPE:
//    - Must wrap the root of your app
//    - Only need ONE at the root (don't nest multiple)
//    - Manages all providers in your app
//    - Without it, ref.watch/ref.read will fail
//
// 2. WHY AT THE ROOT?
//    Providers need to be accessible from anywhere in your app.
//    By putting ProviderScope at the root, all widgets can access providers.
//
// 3. WHAT IF YOU FORGET IT?
//    You'll get an error like:
//    "No ProviderScope found"
//    "Cannot read providers outside of ProviderScope"
//
// 4. ALTERNATIVE: ProviderScope with overrides
//    Useful for testing or different configurations:
//    ```dart
//    runApp(
//      ProviderScope(
//        overrides: [
//          // Override providers for testing
//          apiClientProvider.overrideWithValue(mockApiClient),
//        ],
//        child: App(),
//      ),
//    );
//    ```
//
// ============================================================================
// 🎯 NEXT STEPS
// ============================================================================
//
// Now that Riverpod is enabled, you can:
// 1. Use ref.watch() in ConsumerWidget
// 2. Use ref.read() to call provider methods
// 3. Use ref.listen() for side effects
//
// ============================================================================
