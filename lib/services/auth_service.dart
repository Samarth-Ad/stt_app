import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Keys for SharedPreferences
  static const String USER_EMAIL_KEY = 'user_email';
  static const String USER_DISPLAY_NAME_KEY = 'user_display_name';
  static const String USER_UID_KEY = 'user_uid';
  static const String USER_PHONE_KEY = 'user_phone';
  static const String IS_LOGGED_IN_KEY = 'is_logged_in';

  // Keys for cached user data
  static const String USER_GENDER_KEY = 'user_gender';
  static const String USER_MEMBERSHIP_KEY = 'user_membership';
  static const String USER_REGISTRATION_DATE_KEY = 'user_registration_date';
  static const String USER_DATA_CACHE_TIMESTAMP_KEY =
      'user_data_cache_timestamp';
  static const String USER_DATA_FULLY_CACHED_KEY = 'user_data_fully_cached';

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

      // Fetch and cache Firestore data for quick access
      await cacheUserData(user.uid);
    }
  }

  // Fetch and cache user data from Firestore
  Future<Map<String, dynamic>> cacheUserData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFullyCached = prefs.getBool(USER_DATA_FULLY_CACHED_KEY) ?? false;

      // If data is already fully cached, just return the cached data
      if (isFullyCached) {
        print("Using fully cached data - skipping Firestore fetch");
        return getCachedUserData();
      }

      print("Fetching data from Firestore for initial caching");
      final userData = await _firestore.collection('users').doc(userId).get();
      Map<String, dynamic> cachedData = {};

      if (userData.exists) {
        final data = userData.data() ?? {};

        // Cache the data in SharedPreferences
        if (data['name'] != null) {
          await prefs.setString(USER_DISPLAY_NAME_KEY, data['name'].toString());
          cachedData['name'] = data['name'].toString();
        }

        if (data['email'] != null) {
          await prefs.setString(USER_EMAIL_KEY, data['email'].toString());
          cachedData['email'] = data['email'].toString();
        }

        if (data['phone'] != null) {
          await prefs.setString(USER_PHONE_KEY, data['phone'].toString());
          cachedData['phone'] = data['phone'].toString();
        }

        if (data['gender'] != null) {
          await prefs.setString(USER_GENDER_KEY, data['gender'].toString());
          cachedData['gender'] = data['gender'].toString();
        }

        if (data['membership'] != null) {
          await prefs.setString(
            USER_MEMBERSHIP_KEY,
            data['membership'].toString(),
          );
          cachedData['membership'] = data['membership'].toString();
        }

        // Handle registration date
        if (data['registrationDate'] is Timestamp) {
          final timestamp = data['registrationDate'] as Timestamp;
          final dateTime = timestamp.toDate();
          final formattedDate =
              '${dateTime.day}/${dateTime.month}/${dateTime.year}';

          await prefs.setString(USER_REGISTRATION_DATE_KEY, formattedDate);
          cachedData['registrationDate'] = formattedDate;
        } else if (data['registrationDate'] != null) {
          await prefs.setString(
            USER_REGISTRATION_DATE_KEY,
            data['registrationDate'].toString(),
          );
          cachedData['registrationDate'] = data['registrationDate'].toString();
        }

        // Set cache timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt(USER_DATA_CACHE_TIMESTAMP_KEY, timestamp);
        cachedData['cacheTimestamp'] = timestamp;

        // Mark data as fully cached - won't fetch from Firestore again unless explicitly refreshed
        await prefs.setBool(USER_DATA_FULLY_CACHED_KEY, true);
        print("Data marked as fully cached");
      }

      return cachedData;
    } catch (e) {
      print('Error caching user data: $e');
      return {};
    }
  }

  // Force refresh the cache from Firestore
  Future<Map<String, dynamic>> forceRefreshCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(USER_UID_KEY) ?? '';

      if (userId.isEmpty || _auth.currentUser == null) {
        return {'error': 'No user logged in'};
      }

      // Clear the fully cached flag to force a refresh
      await prefs.setBool(USER_DATA_FULLY_CACHED_KEY, false);

      // Re-fetch data from Firestore
      return await cacheUserData(userId);
    } catch (e) {
      print('Error refreshing cache: $e');
      return {'error': e.toString()};
    }
  }

  // Get cached user data from local storage
  Future<Map<String, dynamic>> getCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get user ID from local storage
      final userId = prefs.getString(USER_UID_KEY) ?? '';
      final isFullyCached = prefs.getBool(USER_DATA_FULLY_CACHED_KEY) ?? false;

      // If data isn't fully cached yet and user is logged in, cache it
      if (!isFullyCached && userId.isNotEmpty && _auth.currentUser != null) {
        try {
          print("Data not fully cached yet, fetching from Firestore");
          await cacheUserData(userId);
        } catch (e) {
          print('Failed to cache data: $e');
        }
      }

      // Return the cached data (whether it was just cached or already existed)
      return {
        'uid': userId,
        'email': prefs.getString(USER_EMAIL_KEY) ?? '',
        'displayName': prefs.getString(USER_DISPLAY_NAME_KEY) ?? '',
        'phoneNumber': prefs.getString(USER_PHONE_KEY) ?? '',
        'gender': prefs.getString(USER_GENDER_KEY) ?? '',
        'membership': prefs.getString(USER_MEMBERSHIP_KEY) ?? '',
        'registrationDate': prefs.getString(USER_REGISTRATION_DATE_KEY) ?? '',
        'isLoggedIn': prefs.getBool(IS_LOGGED_IN_KEY) ?? false,
        'isFullyCached': isFullyCached,
      };
    } catch (e) {
      print('Error getting cached user data: $e');
      return {'error': e.toString(), 'isLoggedIn': false};
    }
  }

  // Get user data from local storage (for backward compatibility)
  Future<Map<String, dynamic>> getUserFromLocalStorage() async {
    return getCachedUserData();
  }

  // Clear user data from local storage
  Future<void> _clearUserFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(USER_EMAIL_KEY);
    await prefs.remove(USER_DISPLAY_NAME_KEY);
    await prefs.remove(USER_UID_KEY);
    await prefs.remove(USER_PHONE_KEY);
    await prefs.remove(USER_GENDER_KEY);
    await prefs.remove(USER_MEMBERSHIP_KEY);
    await prefs.remove(USER_REGISTRATION_DATE_KEY);
    await prefs.remove(USER_DATA_CACHE_TIMESTAMP_KEY);
    await prefs.remove(USER_DATA_FULLY_CACHED_KEY);
    await prefs.setBool(IS_LOGGED_IN_KEY, false);
  }

  // Check Firebase initialization status
  Future<bool> isFirebaseInitialized() async {
    try {
      // This will throw an error if Firebase is not initialized
      FirebaseAuth.instance.app;
      return true;
    } catch (e) {
      print('Firebase not initialized: $e');
      return false;
    }
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
