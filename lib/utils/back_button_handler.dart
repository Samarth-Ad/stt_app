import 'package:flutter/material.dart';
import 'package:stt_app/UserEnd/Pages/homePage.dart';

/// Helper class to handle back button presses consistently throughout the app
class BackButtonHandler {
  /// Handles device back button press based on context and navigation state
  /// Returns true if the default back behavior should proceed, false to override
  static Future<bool> handleBackPress(BuildContext context) async {
    // Get the current route name
    final String? routeName = ModalRoute.of(context)?.settings.name;

    // If we're on a named route (not in bottom nav), allow normal back behavior
    if (routeName != null) {
      return true;
    }

    // Not on a named route - we're likely in a bottom navigation context
    // Check if we're on the HomePage directly
    if (context.findAncestorWidgetOfExactType<HomePage>() != null) {
      // We're on HomePage, find its state to access the selected tab
      final _HomePageState? homePageState =
          context.findAncestorStateOfType<_HomePageState>();

      // If we can access HomePage state, check if we're on the home tab
      if (homePageState != null) {
        // If not on home tab, go to home tab instead of exiting
        if (homePageState.selectedIndex != 2) {
          homePageState.setSelectedIndex(2);
          return false; // Prevent default back behavior
        }

        // On home tab, show exit confirmation dialog
        return await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Exit App?'),
                    content: const Text(
                      'Are you sure you want to exit the app?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
            ) ??
            false;
      }
    }

    // If we can't find HomePage or we're in another context,
    // navigate back to HomePage as a fallback
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false, // Remove all routes from stack
    );
    return false; // Prevent default back behavior
  }
}
