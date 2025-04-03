import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stt_app/services/auth_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool isNotificationsOn = true;
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  // User data fields
  String _name = '';
  String _email = '';
  String _phone = '';
  String _membership = '';
  String _gender = '';
  String _registrationDate = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current Firebase user data
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Get data from Firebase Authentication
        _email = currentUser.email ?? '';
        _name = currentUser.displayName ?? '';

        // Get data from both Firebase and local storage
        final userData = await _authService.getUserFromLocalStorage();

        // Prioritize Firebase values if available, fallback to local storage
        _name = _name.isNotEmpty ? _name : userData['displayName'] ?? '';
        _email = _email.isNotEmpty ? _email : userData['email'] ?? '';

        // Get additional data from local storage
        final prefs = await SharedPreferences.getInstance();
        _phone = prefs.getString('userPhone') ?? '';
        _gender = prefs.getString('userGender') ?? '';
        _membership = prefs.getString('userMembership') ?? 'Member';
        _registrationDate = prefs.getString('userRegistrationDate') ?? '';

        // Format registration date if available
        if (_registrationDate.isNotEmpty) {
          try {
            final date = DateTime.parse(_registrationDate);
            _registrationDate = '${date.day}/${date.month}/${date.year}';
          } catch (e) {
            print('Error parsing date: $e');
          }
        }
      } else {
        // Not logged in - redirect to login page
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }
      }
    } catch (error) {
      print('Error loading user data: $error');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $error')),
        );
      }
    } finally {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
                                  _name.isNotEmpty
                                      ? Text(
                                        _name.substring(0, 1).toUpperCase(),
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
                        _name.isNotEmpty ? _name : 'User',
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
                        _email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ),
                    if (_phone.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          _phone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                      ),
                    if (_gender.isNotEmpty && _gender != 'Select Gender')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          _gender,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                      ),
                    if (_membership.isNotEmpty)
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
                            _membership,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8B4513),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (_registrationDate.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Member since: $_registrationDate',
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
    );
  }
}
