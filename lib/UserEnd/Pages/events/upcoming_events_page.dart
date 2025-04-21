import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'upcoming_event_details.dart';

class UpcomingEventsPage extends StatefulWidget {
  const UpcomingEventsPage({super.key});

  @override
  State<UpcomingEventsPage> createState() => _UpcomingEventsPageState();
}

class _UpcomingEventsPageState extends State<UpcomingEventsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _isLoading = false;
  List<Event> _events = [];
  List<Event> _filteredEvents = [];

  final List<String> _categories = [
    'All',
    'Beach Cleaning',
    'Tree Plantation',
    'River Cleaning',
    'Fort Cleaning',
    'Food Distribution',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _searchController.addListener(_filterEvents);
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('events')
              .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
              .orderBy('date')
              .get();

      setState(() {
        _events =
            snapshot.docs.map((doc) {
              return Event.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            }).toList();
        _filterEvents();
      });
    } catch (e) {
      print('Error fetching events: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading events: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterEvents() {
    setState(() {
      final String searchTerm = _searchController.text.toLowerCase();
      _filteredEvents =
          _events.where((event) {
            // Filter by search term
            final bool matchesSearch =
                searchTerm.isEmpty ||
                event.title.toLowerCase().contains(searchTerm) ||
                event.description.toLowerCase().contains(searchTerm) ||
                event.location.toLowerCase().contains(searchTerm);

            // Filter by category
            final bool matchesCategory =
                _selectedCategory == 'All' ||
                event.category == _selectedCategory;

            return matchesSearch && matchesCategory;
          }).toList();
    });
  }

  void _setCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filterEvents();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterEvents);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upcoming Events',
          style: TextStyle(color: Color(0xFF8B4513)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF8B4513)),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // Category filters
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _setCategory(category);
                      }
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: const Color(0xFF8B4513).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color:
                          isSelected ? const Color(0xFF8B4513) : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Events list
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B4513),
                      ),
                    )
                    : _filteredEvents.isEmpty
                    ? const Center(
                      child: Text(
                        'No upcoming events found',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _fetchEvents,
                      color: const Color(0xFF8B4513),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = _filteredEvents[index];
                          return _buildEventCard(event);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
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
            // Refresh events when returning from details page
            if (value == true) {
              _fetchEvents();
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                image: DecorationImage(
                  image: AssetImage(event.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B4513).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          event.category,
                          style: const TextStyle(
                            color: Color(0xFF8B4513),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('MMM d, yyyy').format(event.date),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF8B4513),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Capacity
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        size: 16,
                        color: Color(0xFF8B4513),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.registeredUsers.length}/${event.capacity} registered',
                        style: TextStyle(
                          color:
                              event.registeredUsers.length >= event.capacity
                                  ? Colors.red
                                  : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // View details button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      UpcomingEventDetailsPage(event: event),
                            ),
                          ).then((value) {
                            // Refresh events when returning from details page
                            if (value == true) {
                              _fetchEvents();
                            }
                          });
                        },
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            color: Color(0xFF8B4513),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Color(0xFF8B4513),
                      ),
                    ],
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
