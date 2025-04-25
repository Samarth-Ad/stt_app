import 'package:flutter/material.dart';
import 'package:stt_app/Admin/events/edit_event_page.dart';
import 'package:stt_app/Admin/events/event_registrations_page.dart';
import 'package:stt_app/models/event_model.dart';

class EventDetailsPage extends StatefulWidget {
  final Event event;

  const EventDetailsPage({Key? key, required this.event}) : super(key: key);

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  late Event event;
  Map<String, dynamic>? _eventDetails;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    event = widget.event;
    _fetchEventDetails();
  }

  void _fetchEventDetails() {
    // Implement the logic to fetch event details from the backend
    // This is a placeholder and should be replaced with actual implementation
    setState(() {
      _loading = false;
      _eventDetails = {
        'registrations': 10, // Placeholder for registration count
        'capacity': 20, // Placeholder for capacity
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditEventPage(event: widget.event),
                ),
              ).then((_) {
                // Refresh the event details after editing
                _fetchEventDetails();
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => EventRegistrationsPage(event: widget.event),
                ),
              );
            },
          ),
        ],
      ),
      body:
          _loading
              ? Center(child: CircularProgressIndicator())
              : _eventDetails == null
              ? Center(child: Text('Error loading event details'))
              : SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.event.imageUrl.isNotEmpty)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            widget.event.imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: Icon(Icons.error, color: Colors.red),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    SizedBox(height: 16),
                    Text(
                      widget.event.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: 8),
                    _buildInfoRow('Date', _getFormattedDate()),
                    _buildInfoRow('Time', widget.event.time),
                    _buildInfoRow('Location', widget.event.location),
                    SizedBox(height: 16),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('No description available'),
                    SizedBox(height: 24),
                    _buildRegistrationSection(),
                    SizedBox(height: 16),
                    if (_eventDetails!.containsKey('registrations'))
                      _buildRegistrationStatsSection(),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.delete),
                          label: Text('Delete Event'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _confirmDeleteEvent,
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.people),
                          label: Text('View Registrations'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => EventRegistrationsPage(
                                      event: widget.event,
                                    ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildRegistrationStatsSection() {
    final registrations = _eventDetails!['registrations'] as int? ?? 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registration Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text(
                  'Total Registrations: $registrations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            if (_eventDetails!.containsKey('capacity') &&
                _eventDetails!['capacity'] != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  value: registrations / (_eventDetails!['capacity'] as int),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getFormattedDate() {
    // Format the date using the event date
    return '${widget.event.date.day}/${widget.event.date.month}/${widget.event.date.year}';
  }

  void _confirmDeleteEvent() {
    // Implement the logic to confirm the deletion of the event
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildRegistrationSection() {
    // Implement the logic to build the registration section
    return Container();
  }
}
