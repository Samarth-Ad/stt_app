import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isLoggedIn = user != null;
    final String userEmail = user?.email ?? '';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF8B4513)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFF8B4513)),
                ),
                const SizedBox(height: 10),
                Text(
                  isLoggedIn ? 'Hello, User' : 'Welcome!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isLoggedIn)
                  Text(
                    userEmail,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Color(0xFF8B4513)),
            title: const Text('Home'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Color(0xFF8B4513)),
            title: const Text('Cart'),
            onTap: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag, color: Color(0xFF8B4513)),
            title: const Text('My Orders'),
            onTap: () {
              Navigator.pushNamed(context, '/orders');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFF8B4513)),
            title: const Text('Settings'),
            onTap: () {
              // Navigate to settings
              Navigator.pop(context);
            },
          ),
          if (isLoggedIn)
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF8B4513)),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.login, color: Color(0xFF8B4513)),
              title: const Text('Login'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
        ],
      ),
    );
  }
}
