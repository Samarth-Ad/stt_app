import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Keys for SharedPreferences
  static const String USER_EMAIL_KEY = 'user_email';
  static const String USER_DISPLAY_NAME_KEY = 'user_display_name';
  static const String USER_UID_KEY = 'user_uid';
  static const String USER_PHONE_KEY = 'user_phone';
  static const String IS_LOGGED_IN_KEY = 'is_logged_in';

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user data in local storage after successful login
      await _saveUserToLocalStorage(result.user);

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user data in local storage after successful signup
      await _saveUserToLocalStorage(result.user);

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Save user data to local storage
  Future<void> _saveUserToLocalStorage(User? user) async {
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(USER_EMAIL_KEY, user.email ?? '');
      await prefs.setString(USER_DISPLAY_NAME_KEY, user.displayName ?? '');
      await prefs.setString(USER_UID_KEY, user.uid);
      await prefs.setString(USER_PHONE_KEY, user.phoneNumber ?? '');
      await prefs.setBool(IS_LOGGED_IN_KEY, true);
    }
  }

  // Get user data from local storage
  Future<Map<String, dynamic>> getUserFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(USER_EMAIL_KEY) ?? '',
      'displayName': prefs.getString(USER_DISPLAY_NAME_KEY) ?? '',
      'uid': prefs.getString(USER_UID_KEY) ?? '',
      'phoneNumber': prefs.getString(USER_PHONE_KEY) ?? '',
      'isLoggedIn': prefs.getBool(IS_LOGGED_IN_KEY) ?? false,
    };
  }

  // Clear user data from local storage
  Future<void> _clearUserFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(USER_EMAIL_KEY);
    await prefs.remove(USER_DISPLAY_NAME_KEY);
    await prefs.remove(USER_UID_KEY);
    await prefs.remove(USER_PHONE_KEY);
    await prefs.setBool(IS_LOGGED_IN_KEY, false);
  }

  // Sign out
  Future<void> signOut() async {
    await _clearUserFromLocalStorage();
    await _auth.signOut();
  }

  // Simple error handler for auth exceptions
  String handleAuthException(FirebaseAuthException e) {
    String errorMessage;
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'No user found with this email.';
        break;
      case 'wrong-password':
        errorMessage = 'Wrong password.';
        break;
      case 'email-already-in-use':
        errorMessage = 'Email is already in use.';
        break;
      case 'invalid-email':
        errorMessage = 'Invalid email address.';
        break;
      case 'weak-password':
        errorMessage = 'Password is too weak.';
        break;
      default:
        errorMessage = 'An error occurred. Please try again.';
    }
    return errorMessage;
  }
}
