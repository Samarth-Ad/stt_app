import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stt_app/Admin/admin_dashboard.dart';
import 'package:stt_app/Authentication/loginPage.dart';
import 'package:stt_app/Authentication/signUp_page.dart';
import 'package:stt_app/UserEnd/Pages/contact_us/contact_usPage.dart';
import 'package:stt_app/UserEnd/Pages/userProfile/userProfile.dart';
import 'package:stt_app/UserEnd/Pages/homePage.dart';
import 'package:stt_app/UserEnd/Pages/userProfile/editProfile.dart';
import 'package:stt_app/UserEnd/Ecomm-Section/pages/catalog_page.dart';
import 'package:stt_app/UserEnd/Ecomm-Section/pages/cart_page.dart';
import 'package:stt_app/UserEnd/Ecomm-Section/pages/order_history_page.dart';
import 'package:stt_app/UserEnd/Pages/events/events_page.dart';
import 'package:stt_app/UserEnd/Pages/events/events_history_page.dart';
import 'package:stt_app/UserEnd/Pages/donations/donations_page.dart';
import 'package:stt_app/UserEnd/Pages/donations/donations_form_page.dart';
import 'package:stt_app/firebase_options.dart';
import 'package:stt_app/services/auth_service.dart';
import 'package:stt_app/services/safe_registration_handler.dart';

// Admin email constant - make it globally accessible
const String ADMIN_EMAIL = "admin@gmail.com";

// Function to check if a user is an admin
bool isUserAdmin(User? user) {
  return user != null && user.email == ADMIN_EMAIL;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Debug print for app startup
  print("App starting: initializing core components");

  try {
    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");

    // SafeRegistrationHandler will be initialized on first use
    // No explicit initialization needed as it's a simple singleton
    print("SafeRegistrationHandler ready for use");

    // Then initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    print("SharedPreferences initialized successfully");

    // Try to get current user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print("User is logged in: ${currentUser.uid}");

      // Display name from Firebase Auth
      final displayName = currentUser.displayName;
      if (displayName != null && displayName.isNotEmpty) {
        await prefs.setString('user_display_name', displayName);
        print("Saved display name to SharedPreferences: $displayName");
      }

      // Email from Firebase Auth
      final email = currentUser.email;
      if (email != null && email.isNotEmpty) {
        await prefs.setString('user_email', email);
        print("Saved email to SharedPreferences: $email");

        // Store admin status in SharedPreferences for quick access
        await prefs.setBool('is_admin', email == ADMIN_EMAIL);
        print("Admin status saved: ${email == ADMIN_EMAIL}");
      }

      // Mark as fully cached to prevent unnecessary Firestore fetches
      await prefs.setBool('user_data_fully_cached', true);
      print("Marked user data as fully cached");
    } else {
      print("No user is currently logged in");
    }
  } catch (e) {
    print("Error during app initialization: $e");
    // Continue app startup even if initialization fails
  }

  // Run the app regardless of initialization success
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Seveche Thayi Tatpar',
      theme: ThemeData(
        primaryColor: const Color(0xFF8B4513),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B4513)),
        useMaterial3: true,
      ),
      builder: (context, child) {
        // Prevent overflow due to large text scaling
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(
              context,
            ).textScaleFactor.clamp(0.8, 1.1),
          ),
          child: child!,
        );
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B4513)),
            );
          }

          if (snapshot.hasData) {
            // Check if the current user is an admin
            final User user = snapshot.data!;
            print("Auth state changed: User logged in: ${user.email}");
            print("Checking if admin: ${user.email == ADMIN_EMAIL}");

            if (isUserAdmin(user)) {
              // If admin, redirect to admin page
              print("Redirecting to admin page");
              return const AdminPage();
            }

            // Otherwise, set home tab as default for regular users
            currentHomeTab = 2;
            return const HomePage();
          } else {
            return const LoginPage();
          }
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/edit-profile': (context) => const EditProfilePage(),
        '/home':
            (context) => const HomePage(initialTab: 2), // Always go to home tab
        '/catalog': (context) => const CatalogPage(),
        '/cart': (context) => const CartPage(),
        '/orders': (context) => const OrderHistoryPage(),
        '/contact-us': (context) => const ContactUsPage(),
        '/events': (context) => const EventsPage(),
        '/events-history': (context) => const EventsHistoryPage(),
        '/donations': (context) => const DonationsPage(),
        '/donation-form': (context) => const DonationsFormPage(),
        '/admin': (context) {
          // Check if the current user is admin before navigating
          final User? user = FirebaseAuth.instance.currentUser;
          if (isUserAdmin(user)) {
            return const AdminPage();
          } else {
            // Redirect non-admin users to home
            return const HomePage(initialTab: 2);
          }
        },
      },
      // Handle profile navigation
      onGenerateRoute: (settings) {
        if (settings.name == '/profile') {
          // Set profile tab as current
          currentHomeTab = 4; // Profile tab

          try {
            // Check if we're already in a HomePage context
            if (settings.arguments is bool && settings.arguments as bool) {
              // We're already in HomePage, just return the profile page
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/profile'),
                builder: (context) => const UserProfilePage(),
              );
            } else {
              // Navigate to HomePage with profile tab selected
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/home'),
                builder: (context) => const HomePage(initialTab: 4),
              );
            }
          } catch (e) {
            print('Error navigating to profile: $e');
            // Fallback to a safe navigation option
            return MaterialPageRoute(
              settings: const RouteSettings(name: '/home'),
              builder:
                  (context) => const HomePage(
                    initialTab: 2,
                  ), // Go to home tab as fallback
            );
          }
        }
        return null;
      },
    );
  }
}
