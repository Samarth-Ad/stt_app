import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:stt_app/models/event_model.dart';
import 'package:stt_app/services/safe_registration_handler.dart';

class EventRegistrationsPage extends StatefulWidget {
  final Event event;

  const EventRegistrationsPage({Key? key, required this.event})
    : super(key: key);

  @override
  State<EventRegistrationsPage> createState() => _EventRegistrationsPageState();
}

class _EventRegistrationsPageState extends State<EventRegistrationsPage> {
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _exportingData = false;

  // Store the registration count directly, not the full user data
  int get registrationCount => widget.event.registeredUsers.length;

  // Store currently expanded user details
  String? _expandedUserId;
  Map<String, dynamic>? _expandedUserData;
  bool _loadingUserDetails = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch a single user's details
  Future<void> _fetchUserDetails(String userId) async {
    if (_expandedUserId == userId && _expandedUserData != null) {
      // Already loaded this user
      return;
    }

    setState(() {
      _loadingUserDetails = true;
      _expandedUserId = userId;
      _expandedUserData = null;
    });

    try {
      // Get user document
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Get complete user data with all fields
      final userData = userDoc.data() ?? {};
      userData['id'] = userId;

      // Get registration timestamp
      try {
        final registrationDoc =
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('registrations')
                .doc(widget.event.id)
                .get();

        if (registrationDoc.exists) {
          final data = registrationDoc.data() ?? {};
          final Timestamp? timestamp = data['registrationDate'] as Timestamp?;
          userData['registrationDate'] = timestamp?.toDate() ?? DateTime.now();

          // Include any additional registration details
          if (data.containsKey('status')) {
            userData['registrationStatus'] = data['status'];
          }

          if (data.containsKey('notes')) {
            userData['registrationNotes'] = data['notes'];
          }
        }
      } catch (e) {
        print('Error fetching registration timestamp: $e');
        // Set default registration date
        userData['registrationDate'] = DateTime.now();
      }

      // Double-check to ensure phone number is included
      if (!userData.containsKey('phone') || userData['phone'] == null) {
        // Add a placeholder if phone is missing
        userData['phone'] = 'No phone number provided';
      }

      setState(() {
        _expandedUserData = userData;
        _loadingUserDetails = false;
      });
    } catch (e) {
      print('Error fetching user details: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading user details: $e')));
      setState(() {
        _expandedUserData = null;
        _loadingUserDetails = false;
        _expandedUserId = null;
      });
    }
  }

  // Check if a user matches the search query
  Future<bool> _checkIfUserMatchesSearch(String userId, String query) async {
    if (query.isEmpty) return true;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data() ?? {};
      final name = ((data['name'] ?? '') as String).toLowerCase();
      final email = ((data['email'] ?? '') as String).toLowerCase();
      final phone = ((data['phone'] ?? '') as String).toLowerCase();

      query = query.toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          phone.contains(query);
    } catch (e) {
      print('Error checking if user matches search: $e');
      return false;
    }
  }

  // Filter the user IDs based on search query
  Future<List<String>> _getFilteredUserIds() async {
    final List<String> userIds = widget.event.registeredUsers;

    if (_searchQuery.isEmpty) {
      return userIds;
    }

    // Filter user IDs based on search
    List<String> filteredIds = [];
    for (final userId in userIds) {
      final matches = await _checkIfUserMatchesSearch(userId, _searchQuery);
      if (matches) {
        filteredIds.add(userId);
      }
    }

    return filteredIds;
  }

  Future<void> _exportRegistrations() async {
    // Implementation for export functionality
    setState(() {
      _exportingData = true;
    });

    try {
      // Simulate export operation
      await Future.delayed(const Duration(seconds: 2));
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
          if (registrationCount > 0)
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
                      '$registrationCount registrations',
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
          if (registrationCount > 0)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or phone',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                          : null,
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
                    : registrationCount == 0
                    ? const Center(
                      child: Text(
                        'No registrations yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : FutureBuilder<List<String>>(
                      future: _getFilteredUserIds(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF8B4513),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        final userIds = snapshot.data ?? [];

                        if (userIds.isEmpty) {
                          return const Center(
                            child: Text(
                              'No results found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: userIds.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final userId = userIds[index];
                            final isExpanded = userId == _expandedUserId;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  if (isExpanded) {
                                    setState(() {
                                      _expandedUserId = null;
                                      _expandedUserData = null;
                                    });
                                  } else {
                                    _fetchUserDetails(userId);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Basic user info (always shown)
                                      Row(
                                        children: [
                                          FutureBuilder<DocumentSnapshot>(
                                            future:
                                                _firestore
                                                    .collection('users')
                                                    .doc(userId)
                                                    .get(),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return CircleAvatar(
                                                  backgroundColor:
                                                      Colors.brown.shade100,
                                                  child: const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Color(
                                                            0xFF8B4513,
                                                          ),
                                                        ),
                                                  ),
                                                );
                                              }

                                              // Handle possible errors
                                              if (snapshot.hasError ||
                                                  !snapshot.hasData ||
                                                  !snapshot.data!.exists) {
                                                return CircleAvatar(
                                                  backgroundColor:
                                                      Colors.brown.shade100,
                                                  child: const Text(
                                                    '?',
                                                    style: TextStyle(
                                                      color: Color(0xFF8B4513),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                );
                                              }

                                              final data =
                                                  snapshot.data?.data()
                                                      as Map<
                                                        String,
                                                        dynamic
                                                      >? ??
                                                  {};
                                              final name =
                                                  data['name'] as String? ??
                                                  'User';

                                              return CircleAvatar(
                                                backgroundColor:
                                                    Colors.brown.shade100,
                                                child: Text(
                                                  name.isNotEmpty
                                                      ? name
                                                          .substring(0, 1)
                                                          .toUpperCase()
                                                      : 'U',
                                                  style: const TextStyle(
                                                    color: Color(0xFF8B4513),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: FutureBuilder<
                                              DocumentSnapshot
                                            >(
                                              future:
                                                  _firestore
                                                      .collection('users')
                                                      .doc(userId)
                                                      .get(),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                        height: 16,
                                                        width: 100,
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade300,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        height: 12,
                                                        width: 150,
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade200,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }

                                                // Handle cases when user data doesn't exist
                                                if (snapshot.hasError ||
                                                    !snapshot.hasData ||
                                                    !snapshot.data!.exists) {
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Unknown User',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        'User data unavailable',
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }

                                                final data =
                                                    snapshot.data?.data()
                                                        as Map<
                                                          String,
                                                          dynamic
                                                        >? ??
                                                    {};
                                                final name =
                                                    data['name'] as String? ??
                                                    'Unknown User';
                                                final email =
                                                    data['email'] as String? ??
                                                    'No email';
                                                final phone =
                                                    data['phone'] as String? ??
                                                    'No phone';

                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      email,
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.phone,
                                                          size: 14,
                                                          color: Colors.grey,
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          phone,
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                          Icon(
                                            isExpanded
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),

                                      // Expanded user details (shown only when expanded)
                                      if (isExpanded)
                                        _loadingUserDetails
                                            ? const Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 16,
                                              ),
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Color(0xFF8B4513),
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            )
                                            : _expandedUserData != null
                                            ? Padding(
                                              padding: const EdgeInsets.only(
                                                top: 16,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Divider(),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.access_time,
                                                        size: 14,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _expandedUserData!['registrationDate'] !=
                                                                null
                                                            ? 'Registered ${DateFormat('MMM d, y').format(_expandedUserData!['registrationDate'])}'
                                                            : 'Registered',
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.badge,
                                                        size: 14,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'User ID: ${_expandedUserData!['id'] ?? 'Unknown'}',
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  if (_expandedUserData!
                                                          .containsKey(
                                                            'address',
                                                          ) &&
                                                      _expandedUserData!['address'] !=
                                                          null)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 8.0,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.home,
                                                            size: 14,
                                                            color: Colors.grey,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              '${_expandedUserData!['address']}',
                                                              style:
                                                                  const TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .grey,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                  const SizedBox(height: 12),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      OutlinedButton.icon(
                                                        icon: const Icon(
                                                          Icons.mail,
                                                          size: 16,
                                                        ),
                                                        label: const Text(
                                                          'Contact',
                                                        ),
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor:
                                                              Colors.brown,
                                                          side: BorderSide(
                                                            color: Colors.brown,
                                                          ),
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 8,
                                                              ),
                                                        ),
                                                        onPressed: () {
                                                          // Future implementation for contacting user
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Contact feature will be implemented soon',
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  // Add more user details here as needed
                                                ],
                                              ),
                                            )
                                            : const SizedBox.shrink(),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
