import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:stt_app/models/event_model.dart';

class EventRegistrationsPage extends StatefulWidget {
  final Event event;

  const EventRegistrationsPage({Key? key, required this.event})
    : super(key: key);

  @override
  State<EventRegistrationsPage> createState() => _EventRegistrationsPageState();
}

class _EventRegistrationsPageState extends State<EventRegistrationsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _registeredUsers = [];
  String _searchQuery = '';
  bool _exportingData = false;

  @override
  void initState() {
    super.initState();
    _fetchRegisteredUsers();
  }

  Future<void> _fetchRegisteredUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<String> userIds = widget.event.registeredUsers;

      if (userIds.isEmpty) {
        setState(() {
          _registeredUsers = [];
          _isLoading = false;
        });
        return;
      }

      final List<Map<String, dynamic>> userData = [];

      // Due to Firestore limitations, fetch users in batches if there are many
      for (int i = 0; i < userIds.length; i += 10) {
        final int end = (i + 10 < userIds.length) ? i + 10 : userIds.length;
        final List<String> batch = userIds.sublist(i, end);

        final usersSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: batch)
                .get();

        for (final doc in usersSnapshot.docs) {
          final user = doc.data();
          user['id'] = doc.id;

          // Get registration timestamp from the user's registrations subcollection
          try {
            final registrationDoc =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(doc.id)
                    .collection('registrations')
                    .doc(widget.event.id)
                    .get();

            if (registrationDoc.exists) {
              final registrationData = registrationDoc.data();
              final Timestamp? timestamp =
                  registrationData?['registrationDate'] as Timestamp?;
              user['registrationDate'] = timestamp?.toDate() ?? DateTime.now();
            }
          } catch (e) {
            print('Error fetching registration timestamp: $e');
          }

          userData.add(user);
        }
      }

      // Sort by registration timestamp, most recent first
      userData.sort((a, b) {
        final DateTime dateA = a['registrationDate'] ?? DateTime.now();
        final DateTime dateB = b['registrationDate'] ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      setState(() {
        _registeredUsers = userData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching registered users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading registered users: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _registeredUsers;
    }

    final query = _searchQuery.toLowerCase();
    return _registeredUsers.where((user) {
      final name = (user['name'] ?? '').toLowerCase();
      final email = (user['email'] ?? '').toLowerCase();
      final phone = (user['phone'] ?? '').toLowerCase();

      return name.contains(query) ||
          email.contains(query) ||
          phone.contains(query);
    }).toList();
  }

  Future<void> _exportRegistrations() async {
    setState(() {
      _exportingData = true;
    });

    try {
      // This is where you would implement export functionality
      // For example, generating a CSV file and sharing it

      await Future.delayed(
        const Duration(seconds: 2),
      ); // Simulate processing time

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrations exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting data: $e')));
    } finally {
      setState(() {
        _exportingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Registrations',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8B4513),
        elevation: 0,
        actions: [
          if (!_isLoading && _registeredUsers.isNotEmpty)
            IconButton(
              icon:
                  _exportingData
                      ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Icon(Icons.download, color: Colors.white),
              onPressed: _exportingData ? null : _exportRegistrations,
              tooltip: 'Export registrations',
            ),
        ],
      ),
      body: Column(
        children: [
          // Event info header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.brown.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMMM dd, yyyy').format(widget.event.date),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.event.location,
                        style: const TextStyle(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.event.registeredUsers.length} registrations',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search bar
          if (!_isLoading && _registeredUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or phone',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

          // Registrations list
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B4513),
                      ),
                    )
                    : _registeredUsers.isEmpty
                    ? const Center(
                      child: Text(
                        'No registrations yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : _filteredUsers.isEmpty
                    ? const Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredUsers.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return _buildUserCard(user);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.brown.shade100,
                  child: Text(
                    (user['name'] ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF8B4513),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user['email'] ?? 'No email',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      user['phone'] ?? 'No phone',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      user['registrationDate'] != null
                          ? 'Registered ${DateFormat('MMM d, y').format(user['registrationDate'])}'
                          : 'Registered',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
