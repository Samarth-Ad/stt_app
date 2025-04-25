import 'dart:async';
import 'package:stt_app/models/event_model.dart';

// In-memory storage for events (simulates a database)
class LocalEventStorage {
  // Singleton pattern
  static final LocalEventStorage _instance = LocalEventStorage._internal();

  factory LocalEventStorage() {
    return _instance;
  }

  LocalEventStorage._internal() {
    // Initialize with sample data immediately in constructor
    _initializeSampleData();
  }

  // List of events (shared across the app)
  final List<Event> _events = [];

  // Stream controllers to notify listeners of changes
  final _eventStreamController = StreamController<List<Event>>.broadcast();
  final _todayEventStreamController = StreamController<List<Event>>.broadcast();
  final _upcomingEventStreamController =
      StreamController<List<Event>>.broadcast();

  // Get streams
  Stream<List<Event>> get eventsStream => _eventStreamController.stream;
  Stream<List<Event>> get todayEventsStream =>
      _todayEventStreamController.stream;
  Stream<List<Event>> get upcomingEventsStream =>
      _upcomingEventStreamController.stream;

  // Initialize sample data (private implementation)
  void _initializeSampleData() {
    if (_events.isEmpty) {
      // Today's event
      final todayDate = DateTime.now();

      // Add sample events
      _events.add(
        Event(
          id: '1',
          title: 'Blood Donation Camp',
          location: 'City Hospital, Ahmedabad',
          date: todayDate,
          time: '10:00 AM - 4:00 PM',
          imageUrl: 'assets/stt_logo.png',
          isActive: true,
        ),
      );

      // Add upcoming events
      _events.add(
        Event(
          id: '2',
          title: 'Food Distribution Drive',
          location: 'Slum Areas, Ahmedabad',
          date: DateTime(todayDate.year, todayDate.month, todayDate.day + 5),
          time: '9:00 AM - 1:00 PM',
          imageUrl: 'assets/stt_logo.png',
          isActive: true,
        ),
      );

      _events.add(
        Event(
          id: '3',
          title: 'Tree Plantation Drive',
          location: 'City Park, Ahmedabad',
          date: DateTime(todayDate.year, todayDate.month, todayDate.day + 10),
          time: '8:00 AM - 12:00 PM',
          imageUrl: 'assets/stt_logo.png',
          isActive: true,
        ),
      );

      _events.add(
        Event(
          id: '4',
          title: 'Clothes Donation Drive',
          location: 'Orphanage, Ahmedabad',
          date: DateTime(todayDate.year, todayDate.month, todayDate.day + 15),
          time: '11:00 AM - 3:00 PM',
          imageUrl: 'assets/stt_logo.png',
          isActive: true,
        ),
      );

      // Notify listeners about the new events
      _notifyListeners();
    }
  }

  // Public method to initialize or refresh sample data
  void initSampleData() {
    // Notify listeners of current data regardless if events are empty or not
    // This ensures streams emit values when subscribed to
    _notifyListeners();
  }

  // Add an event
  String addEvent(Event event) {
    // Generate a simple ID (in a real app, you'd use UUID or similar)
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Create a copy of the event with the new ID
    final newEvent = event.copyWith(id: id);

    // Add to the list
    _events.add(newEvent);

    // Notify listeners
    _notifyListeners();

    return id;
  }

  // Get all events
  List<Event> getEvents({bool activeOnly = false}) {
    if (activeOnly) {
      return _events.where((event) => event.isActive).toList();
    }
    return List.from(_events);
  }

  // Get event by ID
  Event? getEventById(String id) {
    try {
      return _events.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update event
  void updateEvent(Event updatedEvent) {
    final index = _events.indexWhere((event) => event.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;
      _notifyListeners();
    } else {
      throw Exception("Event not found with ID: ${updatedEvent.id}");
    }
  }

  // Delete event
  void deleteEvent(String id) {
    _events.removeWhere((event) => event.id == id);
    _notifyListeners();
  }

  // Get today's events
  List<Event> getTodayEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _events
        .where(
          (event) =>
              event.isActive &&
              event.date.isAfter(today.subtract(const Duration(seconds: 1))) &&
              event.date.isBefore(tomorrow),
        )
        .toList();
  }

  // Get upcoming events (excluding today)
  List<Event> getUpcomingEvents() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    return _events
        .where(
          (event) =>
              event.isActive &&
              event.date.isAfter(tomorrow.subtract(const Duration(seconds: 1))),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // Notify all listeners of changes
  void _notifyListeners() {
    // Sort events by date before sending
    _events.sort((a, b) => a.date.compareTo(b.date));

    // Notify all event listeners
    _eventStreamController.add(List.from(_events));

    // Notify today's event listeners
    _todayEventStreamController.add(getTodayEvents());

    // Notify upcoming event listeners
    _upcomingEventStreamController.add(getUpcomingEvents());
  }

  // Dispose of stream controllers
  void dispose() {
    _eventStreamController.close();
    _todayEventStreamController.close();
    _upcomingEventStreamController.close();
  }
}

// Service class that provides methods to interact with the local storage
class LocalEventService {
  final LocalEventStorage _storage = LocalEventStorage();

  LocalEventService() {
    // Make sure initial values are emitted
    _storage.initSampleData();
  }

  // Add a new event
  Future<String> addEvent(Event event) async {
    return _storage.addEvent(event);
  }

  // Get all events
  Stream<List<Event>> getEvents({bool activeOnly = false}) {
    // Create a stream that immediately provides current events and then listens for updates
    return Stream.value(
      _storage.getEvents(activeOnly: activeOnly),
    ).asyncExpand((_) => _storage.eventsStream);
  }

  // Get a single event by ID
  Future<Event?> getEventById(String id) async {
    return _storage.getEventById(id);
  }

  // Update an event
  Future<void> updateEvent(Event event) async {
    _storage.updateEvent(event);
  }

  // Delete an event
  Future<void> deleteEvent(String id) async {
    _storage.deleteEvent(id);
  }

  // Get today's events
  Stream<List<Event>> getTodayEvents() {
    // Create a stream that immediately provides today's events and then listens for updates
    return Stream.value(
      _storage.getTodayEvents(),
    ).asyncExpand((_) => _storage.todayEventsStream);
  }

  // Get upcoming events (excluding today)
  Stream<List<Event>> getUpcomingEvents() {
    // Create a stream that immediately provides upcoming events and then listens for updates
    return Stream.value(
      _storage.getUpcomingEvents(),
    ).asyncExpand((_) => _storage.upcomingEventsStream);
  }
}
