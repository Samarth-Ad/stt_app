import 'package:flutter/material.dart';
import 'package:stt_app/Authentication/loginPage.dart';
import 'package:stt_app/Authentication/signUp_page.dart';
import 'package:stt_app/Pages/userProfile/userProfile.dart';
import 'package:stt_app/Pages/homePage.dart';
import 'package:stt_app/Pages/userProfile/editProfile.dart';
import 'package:stt_app/Ecomm-Section/pages/catalog_page.dart';
import 'package:stt_app/Ecomm-Section/pages/cart_page.dart';

void main() {
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
      initialRoute: '/home',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/profile': (context) => const UserProfilePage(),
        '/edit-profile': (context) => const EditProfilePage(),
        '/home': (context) => const HomePage(),
        '/catalog': (context) => const CatalogPage(),
        '/cart': (context) => const CartPage(),
      },
    );
  }
}
