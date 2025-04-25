import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stt_app/models/event_model.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

class EventService {
  final CollectionReference eventsCollection = FirebaseFirestore.instance
      .collection('events');

  // In-memory cache of events
  static List<Event> _cachedEvents = [];
  static bool _cacheInitialized = false;

  // Stream controllers to notify listeners of changes
  static final _eventsStreamController =
      StreamController<List<Event>>.broadcast();
  static final _todayEventsStreamController =
      StreamController<List<Event>>.broadcast();
  static final _upcomingEventsStreamController =
      StreamController<List<Event>>.broadcast();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _cacheKey = 'cached_events';
  final String _lastFetchTimeKey = 'last_events_fetch_time';
  // Cache expiration time (24 hours in milliseconds)
  final int _cacheExpirationTime = 24 * 60 * 60 * 1000;

  // Constructor - initialize cache
  EventService() {
    _initCache();
  }

  // Initialize cache from SharedPreferences
  Future<void> _initCache() async {
    if (!_cacheInitialized) {
      await _loadEventsFromCache();
      _cacheInitialized = true;

      // Try to refresh cache from Firestore in background
      _fetchAndCacheEvents().catchError((e) {
        print('Error refreshing cache from Firestore: $e');
      });
    }
  }

  // Load events from SharedPreferences
  Future<void> _loadEventsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString('cached_events') ?? '[]';
      final List<dynamic> eventsList = json.decode(eventsJson);

      _cachedEvents =
          eventsList
              .map((e) => Event.fromMap(e as Map<String, dynamic>))
              .toList();

      // Sort events by date
      _cachedEvents.sort((a, b) => a.date.compareTo(b.date));

      // Notify stream listeners
      _notifyListeners();

      print('Loaded ${_cachedEvents.length} events from cache');
    } catch (e) {
      print('Error loading events from cache: $e');
      _cachedEvents = [];
    }
  }

  // Save events to SharedPreferences
  Future<void> _saveEventsToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = json.encode(
        _cachedEvents.map((e) => e.toMap()).toList(),
      );
      await prefs.setString('cached_events', eventsJson);
      print('Saved ${_cachedEvents.length} events to cache');
    } catch (e) {
      print('Error saving events to cache: $e');
    }
  }

  // Fetch events from Firestore and update cache
  Future<void> _fetchAndCacheEvents() async {
    try {
      final snapshot = await eventsCollection.get();
      final List<Event> events =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final eventData = {...data, 'id': doc.id};
            return Event.fromMap(eventData);
          }).toList();

      // Update cache
      _cachedEvents = events;

      // Sort events by date
      _cachedEvents.sort((a, b) => a.date.compareTo(b.date));

      // Save to SharedPreferences
      await _saveEventsToCache();

      // Notify stream listeners
      _notifyListeners();

      print('Refreshed cache with ${events.length} events from Firestore');
    } catch (e) {
      print('Error fetching events from Firestore: $e');
      // If fetch fails, we'll continue using the existing cache
    }
  }

  // Notify all listeners of changes
  void _notifyListeners() {
    // Notify all event listeners
    _eventsStreamController.add(List.from(_cachedEvents));

    // Notify today's event listeners
    _todayEventsStreamController.add(_getTodayEvents());

    // Notify upcoming event listeners
    _upcomingEventsStreamController.add(_getUpcomingEvents());
  }

  // Get today's events from cache
  List<Event> _getTodayEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _cachedEvents
        .where(
          (event) =>
              event.isActive &&
              event.date.isAfter(today.subtract(const Duration(seconds: 1))) &&
              event.date.isBefore(tomorrow),
        )
        .toList();
  }

  // Get upcoming events from cache
  List<Event> _getUpcomingEvents() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    return _cachedEvents
        .where(
          (event) =>
              event.isActive &&
              event.date.isAfter(tomorrow.subtract(const Duration(seconds: 1))),
        )
        .toList();
  }

  // Add a new event
  Future<String> addEvent(Event event) async {
    try {
      // First save to Firestore
      DocumentReference docRef = await eventsCollection.add(event.toMap());
      final String eventId = docRef.id;

      // Add to cache with the new ID
      final newEvent = event.copyWith(id: eventId);
      _cachedEvents.add(newEvent);

      // Sort events by date
      _cachedEvents.sort((a, b) => a.date.compareTo(b.date));

      // Save to SharedPreferences
      await _saveEventsToCache();

      // Notify stream listeners
      _notifyListeners();

      return eventId;
    } catch (e) {
      print('Error adding event: $e');
      rethrow;
    }
  }

  // Get all events
  Stream<List<Event>> getEvents({bool activeOnly = false}) {
    // Ensure cache is initialized
    _initCache();

    // Return filtered cached events
    return _eventsStreamController.stream.map((events) {
      if (activeOnly) {
        return events.where((event) => event.isActive).toList();
      }
      return events;
    });
  }

  // Get a single event by ID
  Future<Event?> getEventById(String id) async {
    try {
      // First look in cache
      final cachedEvent = _cachedEvents.firstWhere(
        (event) => event.id == id,
        orElse: () => throw Exception('Event not found in cache'),
      );
      return cachedEvent;
    } catch (_) {
      try {
        // If not in cache, try Firestore
        DocumentSnapshot doc = await eventsCollection.doc(id).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final eventData = {...data, 'id': doc.id};
          return Event.fromMap(eventData);
        }
        return null;
      } catch (e) {
        print('Error getting event: $e');
        rethrow;
      }
    }
  }

  // Update an event
  Future<void> updateEvent(Event event) async {
    try {
      if (event.id == null) {
        throw Exception("Cannot update event without ID");
      }

      // First update in Firestore
      final Map<String, dynamic> data = event.toMap();
      data.remove('id'); // Remove id as it's the document ID

      await eventsCollection.doc(event.id).update(data).catchError((e) {
        print('Error updating event in Firestore: $e');
        // Continue with cache update even if Firestore fails
      });

      // Update in cache
      final index = _cachedEvents.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _cachedEvents[index] = event;
      } else {
        _cachedEvents.add(event);
      }

      // Sort events by date
      _cachedEvents.sort((a, b) => a.date.compareTo(b.date));

      // Save to SharedPreferences
      await _saveEventsToCache();

      // Notify stream listeners
      _notifyListeners();
    } catch (e) {
      print('Error updating event: $e');
      rethrow;
    }
  }

  // Delete an event
  Future<void> deleteEvent(String id) async {
    try {
      // First delete from Firestore
      await eventsCollection.doc(id).delete().catchError((e) {
        print('Error deleting event from Firestore: $e');
        // Continue with cache removal even if Firestore fails
      });

      // Remove from cache
      _cachedEvents.removeWhere((event) => event.id == id);

      // Save to SharedPreferences
      await _saveEventsToCache();

      // Notify stream listeners
      _notifyListeners();
    } catch (e) {
      print('Error deleting event: $e');
      rethrow;
    }
  }

  // Get today's events
  Stream<List<Event>> getTodayEvents() {
    // Ensure cache is initialized
    _initCache();

    return _todayEventsStreamController.stream;
  }

  // Get upcoming events (excluding today)
  Stream<List<Event>> getUpcomingEvents() {
    // Ensure cache is initialized
    _initCache();

    return _upcomingEventsStreamController.stream;
  }

  // Force refresh from Firestore (can be called when network is available)
  Future<void> refreshEvents() async {
    return _fetchAndCacheEvents();
  }

  // Get historical events (past events)
  Future<List<Event>> getHistoricalEvents() async {
    final List<Event> allEvents = await getEventsAsList();
    final now = DateTime.now();

    return allEvents.where((event) {
      final eventDate = event.date;
      return eventDate.isBefore(DateTime(now.year, now.month, now.day));
    }).toList();
  }

  // Get upcoming events (future events)
  Future<List<Event>> getUpcomingEventsFuture() async {
    final List<Event> allEvents = await getEventsAsList();
    final now = DateTime.now();

    return allEvents.where((event) {
      final eventDate = event.date;
      return eventDate.isAfter(DateTime(now.year, now.month, now.day - 1));
    }).toList();
  }

  // Get events with caching
  Future<List<Event>> getEventsAsList() async {
    try {
      // Check if we need to refresh from Firestore
      bool shouldRefreshFromFirestore = await _shouldRefreshCache();

      if (shouldRefreshFromFirestore) {
        return await _fetchEventsFromFirestore();
      } else {
        // Get events from cache
        return await _getEventsFromCache();
      }
    } catch (e) {
      print('Error getting events: $e');
      // If there's an error, try to get from cache as fallback
      try {
        return await _getEventsFromCache();
      } catch (cacheError) {
        print('Error getting events from cache: $cacheError');
        return [];
      }
    }
  }

  // Force refresh events from Firestore
  Future<List<Event>> refreshEventsFuture() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      throw Exception('No internet connection available');
    }

    return await _fetchEventsFromFirestore();
  }

  // Check if we need to refresh the cache
  Future<bool> _shouldRefreshCache() async {
    // Check connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      // No internet, use cache regardless of expiration
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastFetchTime = prefs.getInt(_lastFetchTimeKey);

    // If no last fetch time or cache is expired, refresh from Firestore
    if (lastFetchTime == null) return true;

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    return (currentTime - lastFetchTime) > _cacheExpirationTime;
  }

  // Fetch events from Firestore and update cache
  Future<List<Event>> _fetchEventsFromFirestore() async {
    final eventsSnapshot =
        await _firestore
            .collection('events')
            .orderBy('date', descending: false)
            .get();

    final events =
        eventsSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final eventData = {...data, 'id': doc.id};
          return Event.fromMap(eventData);
        }).toList();

    // Update cache
    await _updateCache(events);
    return events;
  }

  // Get events from cache
  Future<List<Event>> _getEventsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedEventsJson = prefs.getString(_cacheKey);

    if (cachedEventsJson == null || cachedEventsJson.isEmpty) {
      // If no cache, try to fetch from Firestore
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        return await _fetchEventsFromFirestore();
      }
      return [];
    }

    final List<dynamic> decodedData = jsonDecode(cachedEventsJson);
    return decodedData
        .map((item) => Event.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  // Update cache with new events
  Future<void> _updateCache(List<Event> events) async {
    final prefs = await SharedPreferences.getInstance();
    final encodedEvents = jsonEncode(events.map((e) => e.toMap()).toList());

    await prefs.setString(_cacheKey, encodedEvents);
    await prefs.setInt(
      _lastFetchTimeKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
