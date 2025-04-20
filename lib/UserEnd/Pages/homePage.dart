import 'package:flutter/material.dart';
import 'package:stt_app/UserEnd/Pages/events/events_page.dart';
import 'package:stt_app/UserEnd/Pages/events/events_history_page.dart';
import 'package:stt_app/UserEnd/Pages/donations/donations_page.dart';
import 'package:stt_app/UserEnd/Pages/userProfile/userProfile.dart';

// Tracks current tab index for HomePage across rebuilds
int currentHomeTab = 2;

class HomePage extends StatefulWidget {
  // Optional parameter to set initial tab
  final int initialTab;

  const HomePage({Key? key, this.initialTab = -1}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    // If initialTab is provided, use it; otherwise use the stored currentHomeTab
    _selectedIndex =
        widget.initialTab >= 0 ? widget.initialTab : currentHomeTab;
    // Update the stored currentHomeTab
    currentHomeTab = _selectedIndex;
  }

  // Define pages for each tab
  final List<Widget> _pages = [
    const EventsHistoryPage(), // Past Events
    const EventsPage(), // Events page
    const HomeContent(), // Home content
    const DonationsPage(), // Donations page
    const UserProfilePage(), // Profile page included directly
  ];

  void _onTabTapped(int index) {
    // If we're already on this tab, don't do anything
    if (_selectedIndex == index) return;

    // Update local state first
    setState(() {
      _selectedIndex = index;
      // Keep track of the current tab
      currentHomeTab = index;
    });

    // If profile tab is selected, use safe navigation
    if (index == 4) {
      try {
        Navigator.of(context).pushReplacementNamed('/profile', arguments: true);
      } catch (e) {
        print('Error navigating to profile tab: $e');
        // If navigation fails, at least the UI will show the profile tab
        // due to the setState above
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        try {
          // If we're not on the home tab, go to home tab instead of exiting
          if (_selectedIndex != 2) {
            setState(() {
              _selectedIndex = 2;
              currentHomeTab = 2;
            });
            return false; // Don't close the app
          }

          // Show exit confirmation dialog on home tab
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
        } catch (e) {
          print('Error in WillPopScope: $e');
          return false; // Don't exit on error
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(index: _selectedIndex, children: _pages),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF8B4513),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
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
      ),
    );
  }
}

// Home content as a separate StatelessWidget
class HomeContent extends StatelessWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status bar time
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
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
                  label: 'Sign Up For Drives',
                  onTap: () {
                    // Update the current tab and navigate to a new HomePage instance
                    currentHomeTab = 1; // Events tab

                    // Replace the current HomePage with a new one
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
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
      ),
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
        height: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF8B4513),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
