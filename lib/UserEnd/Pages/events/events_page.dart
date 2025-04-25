import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stt_app/models/event_model.dart' as model;
import 'package:stt_app/services/event_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stt_app/services/safe_registration_handler.dart';
import 'package:stt_app/UserEnd/Pages/events/upcoming_event_details.dart'
    as details;

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final EventService eventService = EventService();
  bool _isRefreshing = false;
  bool _isRegistering = false;
  final SafeRegistrationHandler _handler = SafeRegistrationHandler();

  // Helper function to convert from model.Event to details.Event
  details.Event _convertToDetailsEvent(model.Event event) {
    try {
      // Safe image path handling
      String imagePath = 'assets/stt_logo.png'; // Default fallback
      if (event.imageUrl.isNotEmpty) {
        if (event.imageUrl.startsWith('assets/')) {
          imagePath = event.imageUrl;
        }
      }

      return details.Event(
        id: event.id ?? '',
        title: event.title,
        description:
            'No description available', // Provide a default description
        location: event.location,
        date: event.date,
        imageUrl: imagePath,
        capacity: 50, // Default capacity
        registeredUsers: event.registeredUsers,
        category: 'Event', // Default category
      );
    } catch (e) {
      print('Error converting event: $e');
      // Return a fallback event if conversion fails
      return details.Event(
        id: event.id ?? '',
        title: event.title,
        description: 'Error loading event details',
        location: event.location,
        date: DateTime.now(),
        imageUrl: 'assets/stt_logo.png',
        capacity: 50,
        registeredUsers: [],
        category: 'Event',
      );
    }
  }

  Future<void> _refreshEvents() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await eventService.refreshEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Events refreshed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing events: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _registerForEvent(model.Event event) async {
    // Prevent multiple registration attempts
    if (_isRegistering) return;

    setState(() {
      _isRegistering = true;
    });

    try {
      // Check if user is logged in
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to register for events'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if already registered
      if (event.registeredUsers.contains(user.uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are already registered for this event'),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }

      // Check if event is at capacity (assuming a default capacity of 50 if not specified)
      final int capacity =
          50; // This could be part of your event model in the future
      if (event.registeredUsers.length >= capacity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This event is at full capacity'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Use the safe handler to register
      final success = await _handler.registerUserForEvent(
        user.uid,
        event.id ?? '',
      );

      if (success) {
        // Refresh the event data to reflect the registration
        await eventService.refreshEvents();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully registered for the event!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Events',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon:
                _isRefreshing
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B4513),
                        strokeWidth: 2,
                      ),
                    )
                    : Icon(Icons.refresh, color: Color(0xFF8B4513)),
            onPressed: _isRefreshing ? null : _refreshEvents,
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF8B4513)),
            onPressed: () {
              Navigator.pushNamed(context, '/events-history');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's Events Section
              const Text(
                'Today\'s Events',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 16),

              // Stream of today's events
              StreamBuilder<List<model.Event>>(
                stream: eventService.getTodayEvents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B4513),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No events scheduled for today',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children:
                        snapshot.data!
                            .map((event) => _buildEventCard(event, true))
                            .toList(),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Upcoming Events Section
              const Text(
                'Upcoming Events',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 16),

              // Stream of upcoming events
              StreamBuilder<List<model.Event>>(
                stream: eventService.getUpcomingEvents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B4513),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No upcoming events scheduled',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children:
                        snapshot.data!
                            .map((event) => _buildEventCard(event, false))
                            .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(model.Event event, bool isToday) {
    // Check if current user is already registered
    bool isUserRegistered = false;
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      isUserRegistered = event.registeredUsers.contains(currentUser.uid);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isToday ? Border.all(color: Colors.green, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              event.imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 160,
                  color: Colors.brown.shade100,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.brown.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.brown.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Event date
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMMM dd, yyyy').format(event.date),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Event time
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      event.time,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Event location
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.location,
                        style: const TextStyle(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Registration status
                if (isUserRegistered)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          'You are registered',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // View details or Register button
                Row(
                  children: [
                    // View Details Button
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.info_outline),
                        label: const Text('View Details'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => details.UpcomingEventDetailsPage(
                                    event: _convertToDetailsEvent(event),
                                  ),
                            ),
                          ).then((_) {
                            // Refresh data when returning from details page
                            _refreshEvents();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8B4513),
                          side: const BorderSide(color: Color(0xFF8B4513)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Register Button
                    Expanded(
                      child: ElevatedButton.icon(
                        icon:
                            _isRegistering
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.how_to_reg),
                        label: Text(
                          isUserRegistered ? 'Registered' : 'Register',
                        ),
                        onPressed:
                            isUserRegistered || _isRegistering
                                ? null
                                : () => _registerForEvent(event),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B4513),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
