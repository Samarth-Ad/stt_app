import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'upcoming_event_details.dart';

class MyRegistrationsPage extends StatefulWidget {
  const MyRegistrationsPage({super.key});

  @override
  State<MyRegistrationsPage> createState() => _MyRegistrationsPageState();
}

class _MyRegistrationsPageState extends State<MyRegistrationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // New method to get registration IDs directly
  Future<List<String>> _getRegisteredEventIds() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to view your registrations'),
          ),
        );
        return [];
      }

      final userRegistrationsSnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('registrations')
              .get();

      final List<String> eventIds =
          userRegistrationsSnapshot.docs
              .map((doc) => doc['eventId'] as String)
              .toList();

      return eventIds;
    } catch (e) {
      print('Error fetching registration IDs: $e');
      return [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to get event data safely
  Future<Event?> _getEventData(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (doc.exists) {
        return Event.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching event $eventId: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Registrations',
          style: TextStyle(color: Color(0xFF8B4513)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF8B4513)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF8B4513),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF8B4513),
          tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past')],
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B4513)),
              )
              : FutureBuilder<List<String>>(
                future: _getRegisteredEventIds(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B4513),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading registrations: ${snapshot.error}',
                      ),
                    );
                  }

                  final eventIds = snapshot.data ?? [];

                  if (eventIds.isEmpty) {
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEmptyState(true),
                        _buildEmptyState(false),
                      ],
                    );
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEventsList(eventIds, true),
                      _buildEventsList(eventIds, false),
                    ],
                  );
                },
              ),
    );
  }

  Widget _buildEmptyState(bool isUpcoming) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isUpcoming ? Icons.event_available : Icons.history,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            isUpcoming
                ? 'No upcoming events registered'
                : 'No past event registrations',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          if (isUpcoming)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/upcoming-events');
              },
              icon: const Icon(Icons.search),
              label: const Text('Find Events'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<String> eventIds, bool isUpcoming) {
    final now = DateTime.now();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      color: const Color(0xFF8B4513),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: eventIds.length,
        itemBuilder: (context, index) {
          final eventId = eventIds[index];

          return FutureBuilder<Event?>(
            future: _getEventData(eventId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingEventCard();
              }

              if (snapshot.hasError || snapshot.data == null) {
                return _buildErrorEventCard(eventId);
              }

              final event = snapshot.data!;

              // Check if event should be shown in this tab
              final isEventUpcoming = event.date.isAfter(now);
              if (isUpcoming != isEventUpcoming) {
                return const SizedBox.shrink();
              }

              return _buildEventCard(event, isUpcoming);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingEventCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildErrorEventCard(String eventId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Error loading event information',
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                // Could add functionality to remove this registration
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event, bool isUpcoming) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UpcomingEventDetailsPage(event: event),
            ),
          ).then((value) {
            if (value == true) {
              setState(() {});
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Event thumbnail image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.asset(
                event.imageUrl,
                height: 120,
                width: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    width: 100,
                    color: Colors.grey.shade300,
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey.shade500,
                    ),
                  );
                },
              ),
            ),

            // Event details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isUpcoming
                                    ? Colors.green.shade50
                                    : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isUpcoming
                                      ? Colors.green.shade200
                                      : Colors.grey.shade400,
                            ),
                          ),
                          child: Text(
                            isUpcoming ? 'Upcoming' : 'Past',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isUpcoming
                                      ? Colors.green
                                      : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Event title
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Date and time
                    Text(
                      DateFormat('E, MMM d, yyyy').format(event.date),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Color(0xFF8B4513),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Arrow icon
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
