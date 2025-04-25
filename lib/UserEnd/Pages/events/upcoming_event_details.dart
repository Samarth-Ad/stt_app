import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:stt_app/services/safe_registration_handler.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String imageUrl;
  final int capacity;
  final List<String> registeredUsers;
  final String category;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.imageUrl,
    required this.capacity,
    required this.registeredUsers,
    required this.category,
  });

  factory Event.fromMap(Map<String, dynamic> map, String documentId) {
    // Helper function to determine image path safely
    String getImagePath(dynamic imageValue) {
      if (imageValue is String && imageValue.isNotEmpty) {
        if (imageValue.startsWith('assets/')) {
          return imageValue; // Already an asset path
        } else if (imageValue.startsWith('http')) {
          // For network images (to be supported in future)
          return 'assets/stt_logo.png'; // Fallback to local asset for now
        }
      }
      return 'assets/stt_logo.png'; // Default fallback
    }

    return Event(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      date:
          (map['date'] is Timestamp)
              ? (map['date'] as Timestamp).toDate()
              : DateTime.now(),
      imageUrl: getImagePath(map['imageUrl']),
      capacity: map['capacity'] is int ? map['capacity'] : 50,
      registeredUsers: List<String>.from(map['registeredUsers'] ?? []),
      category: map['category'] ?? 'Cleaning Drive',
    );
  }
}

class UpcomingEventDetailsPage extends StatefulWidget {
  final Event event;

  const UpcomingEventDetailsPage({super.key, required this.event});

  @override
  State<UpcomingEventDetailsPage> createState() =>
      _UpcomingEventDetailsPageState();
}

class _UpcomingEventDetailsPageState extends State<UpcomingEventDetailsPage> {
  bool _isRegistered = false;
  bool _isLoading = false;
  final SafeRegistrationHandler _handler = SafeRegistrationHandler();

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _isRegistered = widget.event.registeredUsers.contains(user.uid);
        });
      }
    } catch (e) {
      print('Error checking registration status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _registerForEvent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to register')),
        );
        return;
      }

      // Check if already registered
      if (_isRegistered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are already registered for this event'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Check if the event is at capacity
      if (widget.event.registeredUsers.length >= widget.event.capacity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This event is at full capacity')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Use the safe handler to register
      final success = await _handler.registerUserForEvent(
        user.uid,
        widget.event.id,
      );

      if (success) {
        setState(() {
          _isRegistered = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully registered for the event!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. Please try again.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error registering: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Event Details',
          style: TextStyle(color: Color(0xFF8B4513)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF8B4513)),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B4513)),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Image
                    Container(
                      height: 200,
                      width: double.infinity,
                      child: Image.asset(
                        widget.event.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback for missing images
                          return Container(
                            color: Colors.brown.shade100,
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 64,
                                color: Colors.brown.shade400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Event Info
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Category
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF8B4513,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  widget.event.category,
                                  style: const TextStyle(
                                    color: Color(0xFF8B4513),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${widget.event.registeredUsers.length}/${widget.event.capacity} registered',
                                style: TextStyle(
                                  color:
                                      widget.event.registeredUsers.length >=
                                              widget.event.capacity
                                          ? Colors.red
                                          : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Title
                          Text(
                            widget.event.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B4513),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Date and Time
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Color(0xFF8B4513),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat(
                                  'EEEE, MMMM d, yyyy',
                                ).format(widget.event.date),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Time
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Color(0xFF8B4513),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('h:mm a').format(widget.event.date),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Location
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFF8B4513),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.event.location,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Description
                          const Text(
                            'About this event',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B4513),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.event.description,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 32),

                          // Registration Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isRegistered ||
                                          widget.event.registeredUsers.length >=
                                              widget.event.capacity
                                      ? null
                                      : _registerForEvent,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B4513),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                disabledBackgroundColor: Colors.grey,
                              ),
                              child: Text(
                                _isRegistered
                                    ? 'Already Registered'
                                    : widget.event.registeredUsers.length >=
                                        widget.event.capacity
                                    ? 'Event Full'
                                    : 'Register Now',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          if (_isRegistered)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'You are registered!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Please arrive 15 minutes before the event starts. Bring your own water bottle. More details will be sent to your email.',
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
