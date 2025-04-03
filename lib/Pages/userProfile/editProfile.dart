import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stt_app/services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _membershipController = TextEditingController();
  String _selectedGender = 'Select Gender';
  final List<String> _genders = ['Select Gender', 'Male', 'Female', 'Other'];

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Load user data from Firebase and local storage
    _loadUserData();
  }

  // Load user data from Firebase and local storage
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current Firebase user
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Get data from Firebase Authentication
        _emailController.text = currentUser.email ?? '';
        _nameController.text = currentUser.displayName ?? '';

        // Get data from local storage service
        final userData = await _authService.getUserFromLocalStorage();

        // Set name from Firebase first, then fall back to local storage
        if (_nameController.text.isEmpty) {
          _nameController.text = userData['displayName'] ?? '';
        }

        // Try to load additional data from local storage
        final prefs = await SharedPreferences.getInstance();
        _phoneController.text = prefs.getString('userPhone') ?? '';
        _selectedGender = prefs.getString('userGender') ?? 'Select Gender';
        _membershipController.text =
            prefs.getString('userMembership') ?? 'Member';
      } else {
        // User not logged in, redirect to login page
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to edit your profile')),
          );
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load user data: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save user data to Firebase and local storage
  Future<void> _saveUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get current Firebase user
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Update Firebase Authentication data where possible
        if (_nameController.text.isNotEmpty &&
            _nameController.text != currentUser.displayName) {
          await currentUser.updateDisplayName(_nameController.text);
        }

        // Update password if new password field is not empty
        if (_confirmPasswordController.text.isNotEmpty) {
          if (_passwordController.text.isEmpty) {
            setState(() {
              _errorMessage =
                  'Current password is required to set a new password';
            });
            return;
          }

          try {
            // Reauthenticate with current password
            AuthCredential credential = EmailAuthProvider.credential(
              email: currentUser.email!,
              password: _passwordController.text,
            );
            await currentUser.reauthenticateWithCredential(credential);

            // Update password
            await currentUser.updatePassword(_confirmPasswordController.text);

            // Clear password fields
            _passwordController.clear();
            _confirmPasswordController.clear();
          } catch (e) {
            setState(() {
              _errorMessage = 'Failed to update password: ${e.toString()}';
            });
            return;
          }
        }

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', _nameController.text);
        await prefs.setString('userEmail', _emailController.text);
        await prefs.setString('userPhone', _phoneController.text);
        await prefs.setString('userGender', _selectedGender);
        await prefs.setString('userMembership', _membershipController.text);

        // Update registration date if it doesn't exist
        if (prefs.getString('userRegistrationDate') == null) {
          await prefs.setString(
            'userRegistrationDate',
            DateTime.now().toIso8601String(),
          );
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }

        // Return to profile page
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = 'User not authenticated. Please log in again.';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to update profile: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/stt_logo.png', height: 40, width: 40),
            const SizedBox(width: 8),
            const Text(
              'Edit Profile',
              style: TextStyle(
                color: Color(0xFF8B4513),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B4513)),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error message if any
                      if (_errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),

                      // Full Name
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: 'Email cannot be changed directly',
                        ),
                        readOnly: true, // Email can't be changed directly
                      ),
                      const SizedBox(height: 16),

                      // Phone Number
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Gender Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGender,
                            isExpanded: true,
                            hint: const Text('Gender'),
                            items:
                                _genders
                                    .map(
                                      (gender) => DropdownMenuItem(
                                        value: gender,
                                        child: Text(gender),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // STT Member
                      TextField(
                        controller: _membershipController,
                        decoration: const InputDecoration(
                          labelText: 'STT MEMBER / NON MEMBER',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Divider(),

                      // Password section title
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                        child: Text(
                          'Change Password (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                      ),

                      // Current Password
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Current Password',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: 'Required to change password',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // New Password
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Update Profile Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveUserData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B4513),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'UPDATE PROFILE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _membershipController.dispose();
    super.dispose();
  }
}
