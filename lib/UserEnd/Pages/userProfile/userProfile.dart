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
  bool _hasError = false;
  String _errorMessage = '';

  User? user = FirebaseAuth.instance.currentUser;

  // Force refresh the user reference
  void _refreshUserReference() {
    user = FirebaseAuth.instance.currentUser;
  }

  @override
  void initState() {
    super.initState();
    // Add debug print statements
    print("UserProfilePage: initState called");
    _debugLoadProfile();
  }

  // Emergency debug loading function
  Future<void> _debugLoadProfile() async {
    print("UserProfilePage: Starting emergency debug loading");

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = "";
    });

    try {
      // 1. Try to get the Firebase user directly
      user = FirebaseAuth.instance.currentUser;
      print("UserProfilePage: Firebase user: ${user?.uid ?? 'null'}");

      if (user == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = "No user logged in. Please log in first.";
        });
        return;
      }

      // 2. Try to get data from SharedPreferences directly (skip service layer)
      try {
        final prefs = await SharedPreferences.getInstance();
        print("UserProfilePage: SharedPreferences instance created");

        // Get all available keys for debugging
        final keys = prefs.getKeys();
        print("UserProfilePage: Available SharedPreference keys: $keys");

        // Try to load data directly
        name = prefs.getString('user_display_name') ?? user?.displayName ?? '';
        email = prefs.getString('user_email') ?? user?.email ?? '';
        phone = prefs.getString('user_phone') ?? '';
        gender = prefs.getString('user_gender') ?? '';
        membership = prefs.getString('user_membership') ?? '';
        registrationDate = prefs.getString('user_registration_date') ?? '';

        print("UserProfilePage: Loaded data from SharedPreferences");
        print("UserProfilePage: name=$name, email=$email");

        // Always set loading to false and show what we have
        setState(() {
          _isLoading = false;
        });

        // If we have no data, show a warning but still display the page
        if (name.isEmpty &&
            phone.isEmpty &&
            gender.isEmpty &&
            membership.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Limited profile data available. Try editing your profile.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print("UserProfilePage: Error loading from SharedPreferences: $e");
        // Fallback to Firebase user data only
        setState(() {
          name = user?.displayName ?? '';
          email = user?.email ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print("UserProfilePage: Fatal error in debug loading: $e");
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = "Error loading profile: $e";
      });
    }
  }

  // Force refresh data from Firestore - keep this for the refresh button
  Future<void> _forceRefreshData() async {
    print("UserProfilePage: Manual refresh requested");
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Direct approach to Firestore
      user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user logged in");
      }

      print("UserProfilePage: Fetching from Firestore for user ${user!.uid}");
      final userData =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();

      if (userData.exists) {
        final data = userData.data() ?? {};
        print("UserProfilePage: Firestore data received: $data");

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();

        // Update UI and SharedPreferences
        setState(() {
          if (data['name'] != null) {
            name = data['name'].toString();
            prefs.setString('user_display_name', name);
          }

          if (data['email'] != null) {
            email = data['email'].toString();
            prefs.setString('user_email', email);
          }

          if (data['phone'] != null) {
            phone = data['phone'].toString();
            prefs.setString('user_phone', phone);
          }

          if (data['gender'] != null) {
            gender = data['gender'].toString();
            prefs.setString('user_gender', gender);
          }

          if (data['membership'] != null) {
            membership = data['membership'].toString();
            prefs.setString('user_membership', membership);
          }

          // Handle registration date
          if (data['registrationDate'] is Timestamp) {
            final timestamp = data['registrationDate'] as Timestamp;
            final dateTime = timestamp.toDate();
            registrationDate =
                '${dateTime.day}/${dateTime.month}/${dateTime.year}';
            prefs.setString('user_registration_date', registrationDate);
          }

          _isLoading = false;

          // Mark as fully cached
          prefs.setBool('user_data_fully_cached', true);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile refreshed from server')),
        );
      } else {
        print("UserProfilePage: No Firestore data found");
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No profile data found on server')),
        );
      }
    } catch (e) {
      print("UserProfilePage: Error in manual refresh: $e");
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to refresh profile: $e';
      });
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.pushNamed(context, '/edit-profile');
    // Reload user data when returning from edit profile page with changes
    if (result == true) {
      _debugLoadProfile();
    }
  }

  // Helper method to determine if we're inside a bottom tab navigator
  bool _isInBottomTab(BuildContext context) {
    return ModalRoute.of(context)?.settings.name == null;
  }

  // Handle back button press safely
  void _handleBackNavigation(BuildContext context) {
    try {
      // Check if we can pop the current route
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        // If we can't pop, navigate to home safely
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print('Navigation error: $e');
      // Fallback navigation to home
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're inside a bottom navigation bar or a standalone page
    final bool isInStandalonePage = !_isInBottomTab(context);

    return Scaffold(
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
                    // Use our safe navigation handler
                    _handleBackNavigation(context);
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
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _forceRefreshData,
            tooltip: 'Refresh profile',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
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
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(color: Color(0xFF8B4513)),
                    SizedBox(height: 16),
                    Text(
                      "Loading profile...",
                      style: TextStyle(color: Color(0xFF8B4513)),
                    ),
                  ],
                ),
              )
              : _hasError
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: _debugLoadProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
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
                                Navigator.pushNamed(context, '/events-history');
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
                                    // Replace all routes with login route
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/login',
                                      (route) => false,
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
    );
  }
}
