import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// SafeRegistrationHandler provides a reliable way to handle event registrations
/// and fetch user data while avoiding RangeError issues.
class SafeRegistrationHandler {
  static final SafeRegistrationHandler _instance =
      SafeRegistrationHandler._internal();

  factory SafeRegistrationHandler() => _instance;

  SafeRegistrationHandler._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Safely gets all user data for an event's registered users without using batch or whereIn
  Future<List<Map<String, dynamic>>> getRegisteredUsersForEvent(
    String eventId,
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return [];

    final List<Map<String, dynamic>> userData = [];

    // Get individual users one at a time to avoid any batch issues
    for (final userId in userIds) {
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          // Create user data map
          final user = userDoc.data() ?? {};
          user['id'] = userId;

          // Get registration timestamp from user's registrations collection
          try {
            final registrationDoc =
                await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('registrations')
                    .doc(eventId)
                    .get();

            if (registrationDoc.exists) {
              final registrationData = registrationDoc.data();
              final Timestamp? timestamp =
                  registrationData?['registrationDate'] as Timestamp?;
              user['registrationDate'] = timestamp?.toDate() ?? DateTime.now();
            }
          } catch (e) {
            debugPrint('Error fetching registration timestamp for $userId: $e');
            // Set default registration date
            user['registrationDate'] = DateTime.now();
          }

          userData.add(user);
        }
      } catch (e) {
        debugPrint('Error fetching user $userId: $e');
        // Continue with the next user
      }
    }

    return userData;
  }

  /// Safely fetches events data for a list of event IDs without using batch or whereIn
  Future<List<Map<String, dynamic>>> getEventsData(
    List<String> eventIds,
  ) async {
    if (eventIds.isEmpty) return [];

    final List<Map<String, dynamic>> eventsData = [];

    // Get individual events one at a time
    for (final eventId in eventIds) {
      try {
        final eventDoc =
            await _firestore.collection('events').doc(eventId).get();

        if (eventDoc.exists) {
          final eventData = eventDoc.data() ?? {};
          eventData['id'] = eventId;
          eventsData.add(eventData);
        }
      } catch (e) {
        debugPrint('Error fetching event $eventId: $e');
        // Continue with next event
      }
    }

    return eventsData;
  }

  /// Registers a user for an event safely
  Future<bool> registerUserForEvent(String userId, String eventId) async {
    try {
      // First check if the user is already registered
      final eventDoc = await _firestore.collection('events').doc(eventId).get();

      if (!eventDoc.exists) {
        debugPrint('Event $eventId does not exist');
        return false;
      }

      final eventData = eventDoc.data() ?? {};
      final List<dynamic> registeredUsers = eventData['registeredUsers'] ?? [];

      // If user already registered, return success
      if (registeredUsers.contains(userId)) {
        return true;
      }

      // Add user to event's registered users
      await _firestore.collection('events').doc(eventId).update({
        'registeredUsers': FieldValue.arrayUnion([userId]),
      });

      // Add to user's registrations
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('registrations')
          .doc(eventId)
          .set({
            'eventId': eventId,
            'registrationDate': FieldValue.serverTimestamp(),
            'status': 'registered',
          });

      return true;
    } catch (e) {
      debugPrint('Error registering user $userId for event $eventId: $e');
      return false;
    }
  }
}
