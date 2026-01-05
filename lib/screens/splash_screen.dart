// ============================================================================
// IMPORT SECTION - Bringing in Flutter's tools
// ============================================================================

// This import is CRITICAL! It gives us access to:
// - StatefulWidget, State (for widgets that can change)
// - Scaffold, Center, Text (UI building blocks)
// - Navigator (for moving between screens)
// - Colors (for colors like Colors.white)
// - BuildContext (information about where we are in the app)
// WITHOUT this line, NOTHING will work!
import 'package:flutter/material.dart';

// ============================================================================
// SPLASH SCREEN - The first screen users see when app starts
// ============================================================================

// "StatefulWidget" = a widget that CAN change over time
// We use StatefulWidget (not StatelessWidget) because we need to:
// 1. Wait for 2 seconds
// 2. Then navigate to another screen
// This "waiting and navigating" requires the widget to DO something over time
class SplashScreen extends StatefulWidget {

  // Constructor - runs when creating this screen
  // "const" = this value never changes (makes Flutter faster)
  // "{super.key}" = technical Flutter stuff for tracking this widget
  const SplashScreen({super.key});

  // This method creates the "brain" of the widget (the State)
  // "@override" = we're replacing Flutter's default method
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// ============================================================================
// SPLASH SCREEN STATE - The "brain" that controls the splash screen
// ============================================================================

// The underscore "_" makes this class PRIVATE (only this file can use it)
// "State<SplashScreen>" = this is the brain for the SplashScreen widget
class _SplashScreenState extends State<SplashScreen> {

  // ============================================================================
  // INIT STATE - Runs ONCE when this screen first appears
  // ============================================================================

  // This is like the "constructor" for State classes
  // It runs IMMEDIATELY when the screen is created
  // "@override" = we're replacing Flutter's default initState
  @override
  void initState() {

    // ALWAYS call super.initState() first!
    // This lets Flutter do its internal setup before we do our stuff
    super.initState();

    // Now start our navigation process
    _navigateToNextScreen();
  }

  // ============================================================================
  // NAVIGATION METHOD - Waits 2 seconds, then goes to login screen
  // ============================================================================

  // "Future<void>" = this function does something that takes time (asynchronous)
  // "async" = this function can "await" (wait for) things to finish
  Future<void> _navigateToNextScreen() async {

    // WAIT for 2 seconds before doing anything
    // "await" = pause here until the 2 seconds are up
    // "Future.delayed" = a timer that waits
    // "Duration(seconds: 2)" = wait for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    // Check if the widget is still "mounted" (still exists on screen)
    // Why? Because the user might have closed the app during those 2 seconds!
    // If we try to navigate when the widget is gone, the app will CRASH
    if (mounted) {

      // Navigate to the login screen
      // "Navigator" = Flutter's tool for moving between screens
      // "pushReplacementNamed" = go to a new screen AND remove this one
      //   (so user can't press "back" to return to splash screen)
      // "context" = tells Flutter where we are in the widget tree
      // "'/login'" = the name/address of the login screen (defined in main.dart)
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ============================================================================
  // BUILD METHOD - Describes what the splash screen LOOKS like
  // ============================================================================

  // This method draws/paints the UI on the screen
  // "@override" = replacing Flutter's default build method
  // "Widget" = everything in Flutter is a widget (building block)
  // "BuildContext context" = info about where we are in the widget tree
  @override
  Widget build(BuildContext context) {

    // "return" = give back the UI that Flutter should display
    // "const" = this UI never changes (makes Flutter faster)
    return const Scaffold(

      // Scaffold = basic screen structure (like a blank canvas)
      // It provides things like: background color, app bar, body, etc.

      // ========================================================================
      // BACKGROUND COLOR
      // ========================================================================
      backgroundColor: Colors.white,  // White background

      // ========================================================================
      // BODY - The main content of the screen
      // ========================================================================
      body: Center(

        // Center = centers its child widget in the middle of the screen
        // Both horizontally (left-right) AND vertically (up-down)

        child: Text(

          // Text widget displays text on screen
          'Loading...',  // The text to show

          // You can add more styling here if you want:
          // style: TextStyle(
          //   fontSize: 20,
          //   color: Colors.green,
          //   fontWeight: FontWeight.bold,
          // ),
        ),
      ),
    );
  }
}

// ============================================================================
// SUMMARY - What this file does:
// ============================================================================
// 1. Shows a white screen with "Loading..." text in the center
// 2. Waits for 2 seconds
// 3. Automatically navigates to the login screen
// 4. Uses StatefulWidget because it needs to DO something over time
// ============================================================================

// ============================================================================
// FLOW OF EXECUTION:
// ============================================================================
// 1. User opens app
// 2. main.dart starts and shows SplashScreen
// 3. SplashScreen is created → createState() runs → creates _SplashScreenState
// 4. _SplashScreenState's initState() runs immediately
// 5. initState() calls _navigateToNextScreen()
// 6. _navigateToNextScreen() waits 2 seconds
// 7. After 2 seconds, checks if widget still exists (mounted)
// 8. Navigates to login screen using Navigator.pushReplacementNamed()
// 9. SplashScreen is removed from memory (replaced by LoginScreen)
// ============================================================================