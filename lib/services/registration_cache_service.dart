import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// A service to cache user and registration data to avoid Firestore query limitations
class RegistrationCacheService {
  static final RegistrationCacheService _instance =
      RegistrationCacheService._internal();
  factory RegistrationCacheService() => _instance;
  RegistrationCacheService._internal();

  static const String _usersCacheKey = 'cached_users_data';
  static const String _lastCacheUpdateKey = 'last_users_cache_update';
  static const Duration _cacheExpiration = Duration(hours: 12);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, Map<String, dynamic>> _usersCache = {};
  bool _isInitialized = false;

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadCacheFromPrefs();
    _isInitialized = true;
  }

  /// Get user data for a list of user IDs, using cache when possible
  Future<List<Map<String, dynamic>>> getUsersData(List<String> userIds) async {
    if (!_isInitialized) await initialize();

    // Check if cache refresh is needed
    final shouldRefreshCache = await _shouldRefreshCache();
    if (shouldRefreshCache) {
      await _refreshUsersCache();
    }

    // Find users that are not in cache
    final List<String> missingUserIds =
        userIds.where((id) => !_usersCache.containsKey(id)).toList();

    // Fetch missing users from Firestore
    if (missingUserIds.isNotEmpty) {
      await _fetchAndCacheUsers(missingUserIds);
    }

    // Return data from cache
    final List<Map<String, dynamic>> result = [];
    for (final userId in userIds) {
      if (_usersCache.containsKey(userId)) {
        final userData = Map<String, dynamic>.from(_usersCache[userId]!);
        userData['id'] = userId; // Ensure ID is included
        result.add(userData);
      }
    }

    return result;
  }

  /// Get user registration data for a specific event
  Future<List<Map<String, dynamic>>> getUsersForEvent(
    String eventId,
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return [];

    // Get basic user data from cache
    final List<Map<String, dynamic>> usersData = await getUsersData(userIds);

    // Add registration timestamp to each user
    final List<Map<String, dynamic>> usersWithRegistrations = [];

    for (final user in usersData) {
      final userId = user['id'];
      final Map<String, dynamic> enhancedUser = Map.from(user);

      try {
        // Get registration timestamp
        final registrationDoc =
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('registrations')
                .doc(eventId)
                .get();

        if (registrationDoc.exists) {
          final data = registrationDoc.data();
          final Timestamp? timestamp = data?['registrationDate'] as Timestamp?;
          enhancedUser['registrationDate'] =
              timestamp?.toDate() ?? DateTime.now();
        }

        usersWithRegistrations.add(enhancedUser);
      } catch (e) {
        print('Error fetching registration for user $userId: $e');
        enhancedUser['registrationDate'] = DateTime.now();
        usersWithRegistrations.add(enhancedUser);
      }
    }

    return usersWithRegistrations;
  }

  /// Load cache from SharedPreferences
  Future<void> _loadCacheFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_usersCacheKey);

      if (cachedData != null) {
        final Map<String, dynamic> decoded = jsonDecode(cachedData);
        _usersCache = decoded.map(
          (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
        );
        print('Loaded ${_usersCache.length} users from cache');
      }
    } catch (e) {
      print('Error loading users cache: $e');
      _usersCache = {};
    }
  }

  /// Save cache to SharedPreferences
  Future<void> _saveCacheToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(_usersCache);
      await prefs.setString(_usersCacheKey, jsonData);
      await prefs.setInt(
        _lastCacheUpdateKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      print('Saved ${_usersCache.length} users to cache');
    } catch (e) {
      print('Error saving users cache: $e');
    }
  }

  /// Check if cache refresh is needed
  Future<bool> _shouldRefreshCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? lastUpdate = prefs.getInt(_lastCacheUpdateKey);

      if (lastUpdate == null) return true;

      final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      final now = DateTime.now();

      return now.difference(lastUpdateTime) > _cacheExpiration;
    } catch (e) {
      print('Error checking cache freshness: $e');
      return true;
    }
  }

  /// Refresh the entire users cache with latest data
  Future<void> _refreshUsersCache() async {
    try {
      // Get all existing users to refresh
      final userIds = _usersCache.keys.toList();

      if (userIds.isNotEmpty) {
        await _fetchAndCacheUsers(userIds, forceRefresh: true);
      }
    } catch (e) {
      print('Error refreshing users cache: $e');
    }
  }

  /// Fetch users from Firestore and add to cache
  Future<void> _fetchAndCacheUsers(
    List<String> userIds, {
    bool forceRefresh = false,
  }) async {
    if (userIds.isEmpty) return;

    try {
      // Process in safe batches of 10 (Firestore limit for whereIn)
      for (int i = 0; i < userIds.length; i += 10) {
        final int end = (i + 10 < userIds.length) ? i + 10 : userIds.length;
        final List<String> batch = userIds.sublist(i, end);

        if (batch.isEmpty) continue;

        // Single-item special case - avoid whereIn for single item
        if (batch.length == 1) {
          final userId = batch[0];
          final docSnapshot =
              await _firestore.collection('users').doc(userId).get();

          if (docSnapshot.exists) {
            final userData = docSnapshot.data() ?? {};
            _usersCache[userId] = userData;
          }
        } else {
          // Multiple items - use whereIn
          final querySnapshot =
              await _firestore
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: batch)
                  .get();

          for (final doc in querySnapshot.docs) {
            _usersCache[doc.id] = doc.data();
          }
        }
      }

      // Save updated cache
      await _saveCacheToPrefs();
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  /// Clear the cache (useful for debugging or on logout)
  Future<void> clearCache() async {
    try {
      _usersCache.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_usersCacheKey);
      await prefs.remove(_lastCacheUpdateKey);
      print('Users cache cleared');
    } catch (e) {
      print('Error clearing users cache: $e');
    }
  }
}
