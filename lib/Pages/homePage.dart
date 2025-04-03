import 'package:flutter/material.dart';
import 'package:stt_app/Pages/events/events_page.dart';
import 'package:stt_app/Pages/events/events_history_page.dart';
import 'package:stt_app/Pages/donations/donations_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2; // Home tab is selected by default

  // Define pages for each tab
  late final List<Widget> _pages = [
    const EventsHistoryPage(), // Calendar replaced with Events History
    const EventsPage(), // Events page
    _buildHomeContent(), // Home content
    const DonationsPage(), // Donations page
    Container(), // Profile page (handled via navigation)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Show selected page based on bottom nav selection
        child:
            _selectedIndex == 2
                ? SingleChildScrollView(child: _buildHomeContent())
                : _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF8B4513),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          // Handle profile navigation
          if (index == 4) {
            Navigator.pushNamed(context, '/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Past Events',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism),
            label: 'Donations',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status bar time
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: const [
              Text(
                '9:41',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Main Image Container
        Container(
          height: 300, // Adjust height as needed
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
              image: AssetImage('assets/stt_logo.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Action Buttons Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.shopping_cart,
                label: 'Shopping',
                onTap: () {
                  Navigator.pushNamed(context, '/catalog');
                },
              ),
              _buildActionButton(
                icon: Icons.phone,
                label: 'Contact Us',
                onTap: () {
                  Navigator.pushNamed(context, '/contact-us');
                },
              ),
              _buildActionButton(
                icon: Icons.touch_app,
                label: 'Sign Up For\nDrives',
                onTap: () {
                  // Navigate to events page for registration
                  setState(() {
                    _selectedIndex = 1; // Events tab
                  });
                },
              ),
            ],
          ),
        ),

        // Announcements Section
        Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Announcements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              SizedBox(height: 16),
              // Add announcement content here
              Text(
                'Join us for our upcoming Blood Donation Drive!',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'New clothes collection drive starting next week.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF8B4513),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
