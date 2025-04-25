import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:stt_app/models/event_model.dart';
import 'package:stt_app/services/event_service.dart';
import 'package:stt_app/Admin/events/add_event_page.dart';
import 'package:stt_app/Admin/events/edit_event_page.dart';

class ManageEventsPage extends StatefulWidget {
  const ManageEventsPage({super.key});

  @override
  State<ManageEventsPage> createState() => _ManageEventsPageState();
}

class _ManageEventsPageState extends State<ManageEventsPage> {
  final EventService _eventService = EventService();
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _initialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    // Initialize event service and force a refresh when page opens
    _performInitialLoad();
  }

  Future<void> _performInitialLoad() async {
    if (_isRefreshing) return;

    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });

    try {
      // Set a timeout to prevent getting stuck
      await Future.wait([
        _eventService.refreshEvents().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Connection timed out, please try again');
          },
        ),
      ]);

      if (mounted) {
        setState(() {
          _initialLoadComplete = true;
        });
      }
    } catch (e) {
      print('Error during initial load: $e');
      if (mounted) {
        // Even if there's an error, mark as complete to show UI
        setState(() {
          _initialLoadComplete = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not load events: ${e.toString().split('\n')[0]}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'RETRY',
              onPressed: _refreshEvents,
              textColor: Colors.white,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshEvents() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _eventService.refreshEvents().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out, please try again');
        },
      );

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
            content: Text(
              'Error refreshing events: ${e.toString().split('\n')[0]}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'RETRY',
              onPressed: _refreshEvents,
              textColor: Colors.white,
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Events',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8B4513),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon:
                _isRefreshing
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : Icon(Icons.refresh, color: Colors.white),
            onPressed: _isRefreshing ? null : _refreshEvents,
            tooltip: 'Refresh events',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Events',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Event'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddEventPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading && !_initialLoadComplete
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF8B4513)),
                          SizedBox(height: 16),
                          Text(
                            'Loading events...',
                            style: TextStyle(color: Color(0xFF8B4513)),
                          ),
                        ],
                      ),
                    )
                    : StreamBuilder<List<Event>>(
                      stream: _eventService.getEvents(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !_initialLoadComplete) {
                          // Show loading indicator only if initial load isn't complete
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF8B4513),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Error loading events: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try Again'),
                                  onPressed: _refreshEvents,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B4513),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'No events found. Add your first event!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        final events = snapshot.data!;
                        return RefreshIndicator(
                          onRefresh: _refreshEvents,
                          color: const Color(0xFF8B4513),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              final event = events[index];
                              return _buildEventCard(event);
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final bool isPastEvent = event.date.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              event.isActive
                  ? Colors.green.withOpacity(0.5)
                  : Colors.red.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        event.isActive
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color:
                          event.isActive
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMMM dd, yyyy').format(event.date),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(event.time, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit button
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEventPage(event: event),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
                const SizedBox(width: 8),
                // Delete button
                TextButton.icon(
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  onPressed: () => _confirmDeleteEvent(event),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteEvent(Event event) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Event'),
            content: Text('Are you sure you want to delete "${event.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    await _eventService.deleteEvent(event.id!);
                    if (mounted) {
                      // Refresh events after deletion
                      await _refreshEvents();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Event deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting event: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
