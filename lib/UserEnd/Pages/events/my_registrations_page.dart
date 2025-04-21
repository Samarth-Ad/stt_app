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
  List<Event> _upcomingEvents = [];
  List<Event> _pastEvents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRegisteredEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRegisteredEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to view your registrations'),
          ),
        );
        return;
      }

      // Get all events the user has registered for
      final userRegistrationsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('registrations')
              .get();

      final List<String> eventIds =
          userRegistrationsSnapshot.docs
              .map((doc) => doc['eventId'] as String)
              .toList();

      if (eventIds.isEmpty) {
        setState(() {
          _upcomingEvents = [];
          _pastEvents = [];
          _isLoading = false;
        });
        return;
      }

      // Fetch the actual event data
      List<Event> allEvents = [];

      // Due to Firestore limitations, we need to fetch events in batches if there are many
      for (int i = 0; i < eventIds.length; i += 10) {
        final int end = (i + 10 < eventIds.length) ? i + 10 : eventIds.length;
        final List<String> batch = eventIds.sublist(i, end);

        final eventsSnapshot =
            await FirebaseFirestore.instance
                .collection('events')
                .where(FieldPath.documentId, whereIn: batch)
                .get();

        final batchEvents =
            eventsSnapshot.docs.map((doc) {
              return Event.fromMap(doc.data(), doc.id);
            }).toList();

        allEvents.addAll(batchEvents);
      }

      // Split into upcoming and past events
      final now = DateTime.now();
      setState(() {
        _upcomingEvents =
            allEvents.where((event) => event.date.isAfter(now)).toList()
              ..sort((a, b) => a.date.compareTo(b.date));

        _pastEvents =
            allEvents.where((event) => event.date.isBefore(now)).toList()
              ..sort((a, b) => b.date.compareTo(a.date)); // Newest first

        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching registered events: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading your registrations: $e')),
      );
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
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildEventsList(_upcomingEvents, true),
                  _buildEventsList(_pastEvents, false),
                ],
              ),
    );
  }

  Widget _buildEventsList(List<Event> events, bool isUpcoming) {
    if (events.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: _fetchRegisteredEvents,
      color: const Color(0xFF8B4513),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildEventCard(event, isUpcoming);
        },
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
              _fetchRegisteredEvents();
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
                      DateFormat('E, MMM d, yyyy • h:mm a').format(event.date),
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
