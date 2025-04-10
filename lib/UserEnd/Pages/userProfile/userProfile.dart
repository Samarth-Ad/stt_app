import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stt_app/UserEnd/Pages/homePage.dart';
import 'package:stt_app/services/auth_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool isNotificationsOn = true;
  final AuthService _authService = AuthService();

  // User data fields
  String name = "";
  String email = "";
  String phone = "";
  String membership = "";
  String gender = "";
  String registrationDate = "";
  bool _isLoading = true;

  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      try {
        final userData =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .get();

        if (userData.exists) {
          final data = userData.data();
          if (mounted) {
            setState(() {
              name = data?['name']?.toString().trim() ?? '';
              email = data?['email']?.toString().trim() ?? '';
              phone = data?['phone']?.toString().trim() ?? '';
              membership = data?['membership']?.toString().trim() ?? '';
              gender = data?['gender']?.toString().trim() ?? '';

              // Convert Timestamp to formatted date string
              if (data?['registrationDate'] is Timestamp) {
                final timestamp = data?['registrationDate'] as Timestamp;
                final dateTime = timestamp.toDate();
                registrationDate =
                    '${dateTime.day}/${dateTime.month}/${dateTime.year}';
              } else {
                registrationDate =
                    data?['registrationDate']?.toString().trim() ?? '';
              }

              _isLoading = false;
            });
          }
        }
      } catch (e) {
        print('Error loading user data: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToEditProfile() async {
    await Navigator.pushNamed(context, '/edit-profile');
    // Reload user data when returning from edit profile page
    _loadUserData();
  }

  // Handle back button press
  Future<bool> _onWillPop() async {
    // Check if we're in a standalone page or in the tab navigator
    final bool isInStandalonePage =
        ModalRoute.of(context)?.settings.name != null;

    if (isInStandalonePage) {
      // If accessed via named route, just allow the normal back behavior
      return true;
    }

    // If inside bottom nav, set home tab as current and navigate to HomePage
    currentHomeTab = 2; // Home tab

    // Replace with a new HomePage instance that will show the home tab
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );

    return false; // Prevent default back button behavior
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're inside a bottom navigation bar or a standalone page
    final bool isInStandalonePage =
        ModalRoute.of(context)?.settings.name != null;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading:
              isInStandalonePage, // Only show back button in standalone mode
          leading:
              isInStandalonePage
                  ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                  : null,
          title: const Text(
            'User Profile',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.black,
              ),
              onPressed: () {
                // Handle notification button press
              },
            ),
            IconButton(
              icon: const Icon(Icons.access_time, color: Colors.black),
              onPressed: () {
                // Handle time/history button press
              },
            ),
            if (isInStandalonePage)
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.black),
                onPressed: () {
                  // Handle more options button press
                },
              ),
          ],
        ),
        body:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B4513)),
                )
                : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Only show this title when in bottom tab navigation
                      if (!isInStandalonePage)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'User Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B4513),
                            ),
                          ),
                        ),

                      // Profile header with avatar
                      Container(
                        color: const Color(0xFFEDF5F6),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.lightBlue.shade200,
                                child:
                                    name.isNotEmpty
                                        ? Text(
                                          name.substring(0, 1).toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 40,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                        : const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _navigateToEditProfile,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // User info
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          name.isNotEmpty ? name : 'User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                        child: Text(
                          email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                      ),
                      if (phone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8B4513),
                            ),
                          ),
                        ),
                      if (gender.isNotEmpty && gender != 'Select Gender')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            gender,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8B4513),
                            ),
                          ),
                        ),
                      if (membership.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B4513).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              membership,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8B4513),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (registrationDate.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Member since: $registrationDate',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      // Profile options
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.edit_document,
                                  color: Color(0xFF8B4513),
                                ),
                                title: const Text(
                                  'Edit profile information',
                                  style: TextStyle(color: Color(0xFF8B4513)),
                                ),
                                onTap: _navigateToEditProfile,
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(
                                  Icons.notifications_outlined,
                                  color: Color(0xFF8B4513),
                                ),
                                title: const Text(
                                  'Notifications',
                                  style: TextStyle(color: Color(0xFF8B4513)),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isNotificationsOn ? 'ON' : 'OFF',
                                      style: TextStyle(
                                        color:
                                            isNotificationsOn
                                                ? Colors.blue
                                                : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Switch(
                                      value: isNotificationsOn,
                                      onChanged: (value) {
                                        setState(() {
                                          isNotificationsOn = value;
                                        });
                                      },
                                      activeColor: Colors.blue,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Events section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.event,
                                  color: Color(0xFF8B4513),
                                ),
                                title: const Text(
                                  'Events scheduled',
                                  style: TextStyle(color: Color(0xFF8B4513)),
                                ),
                                onTap: () {
                                  // Navigate to events page
                                  Navigator.pushNamed(context, '/events');
                                },
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(
                                  Icons.history,
                                  color: Color(0xFF8B4513),
                                ),
                                title: const Text(
                                  'Events Missed',
                                  style: TextStyle(color: Color(0xFF8B4513)),
                                ),
                                onTap: () {
                                  // Navigate to events history page
                                  Navigator.pushNamed(
                                    context,
                                    '/events-history',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Theme and logout
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.palette,
                                  color: Color(0xFF8B4513),
                                ),
                                title: const Text(
                                  'Theme',
                                  style: TextStyle(color: Color(0xFF8B4513)),
                                ),
                                trailing: const Text(
                                  'Light mode ▼',
                                  style: TextStyle(color: Colors.blue),
                                ),
                                onTap: () {
                                  // Handle theme change
                                },
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(
                                  Icons.logout,
                                  color: Color(0xFF8B4513),
                                ),
                                title: const Text(
                                  'Logout',
                                  style: TextStyle(color: Color(0xFF8B4513)),
                                ),
                                onTap: () async {
                                  try {
                                    await _authService.signOut();
                                    if (mounted) {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/login',
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error signing out: $e'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
      ),
    );
  }
}
