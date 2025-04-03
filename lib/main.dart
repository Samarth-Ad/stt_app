import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stt_app/Authentication/loginPage.dart';
import 'package:stt_app/Authentication/signUp_page.dart';
import 'package:stt_app/Pages/contact_us/contact_usPage.dart';
import 'package:stt_app/Pages/userProfile/userProfile.dart';
import 'package:stt_app/Pages/homePage.dart';
import 'package:stt_app/Pages/userProfile/editProfile.dart';
import 'package:stt_app/Ecomm-Section/pages/catalog_page.dart';
import 'package:stt_app/Ecomm-Section/pages/cart_page.dart';
import 'package:stt_app/Pages/events/events_page.dart';
import 'package:stt_app/Pages/events/events_history_page.dart';
import 'package:stt_app/Pages/donations/donations_page.dart';
import 'package:stt_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B4513)),
            );
          }

          if (snapshot.hasData) {
            return const HomePage();
          } else {
            return const LoginPage();
          }
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/profile': (context) => const UserProfilePage(),
        '/edit-profile': (context) => const EditProfilePage(),
        '/home': (context) => const HomePage(),
        '/catalog': (context) => const CatalogPage(),
        '/cart': (context) => const CartPage(),
        '/contact-us': (context) => const ContactUsPage(),
        '/events': (context) => const EventsPage(),
        '/events-history': (context) => const EventsHistoryPage(),
        '/donations': (context) => const DonationsPage(),
      },
    );
  }
}
