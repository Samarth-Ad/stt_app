import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  bool _isLoading = false;
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Users',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8B4513),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B4513)),
              )
              : StreamBuilder<QuerySnapshot>(
                stream: _usersCollection.snapshots(),
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

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData =
                          users[index].data() as Map<String, dynamic>;
                      final userId = users[index].id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF8B4513),
                            child: Text(
                              (userData['name'] as String?)?.isNotEmpty == true
                                  ? (userData['name'] as String)
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : (userData['email'] as String?)
                                          ?.isNotEmpty ==
                                      true
                                  ? (userData['email'] as String)
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            userData['name'] ?? 'No Name',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userData['email'] ?? 'No Email'),
                              Text('Phone: ${userData['phone'] ?? 'N/A'}'),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'details',
                                    child: Text('View Details'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete User'),
                                  ),
                                ],
                            onSelected: (value) {
                              if (value == 'details') {
                                _showUserDetails(userData, userId);
                              } else if (value == 'delete') {
                                _confirmDeleteUser(userId);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }

  void _showUserDetails(Map<String, dynamic> userData, String userId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('User Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('User ID', userId),
                  _buildDetailRow('Name', userData['name'] ?? 'Not provided'),
                  _buildDetailRow('Email', userData['email'] ?? 'Not provided'),
                  _buildDetailRow('Phone', userData['phone'] ?? 'Not provided'),
                  _buildDetailRow(
                    'Membership',
                    userData['membership'] ?? 'Not specified',
                  ),
                  _buildDetailRow(
                    'Gender',
                    userData['gender'] ?? 'Not specified',
                  ),
                  _buildDetailRow(
                    'Registration Date',
                    userData['registrationDate'] != null
                        ? (userData['registrationDate'] as Timestamp)
                            .toDate()
                            .toString()
                        : 'Not available',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
          Text(value),
          const Divider(),
        ],
      ),
    );
  }

  void _confirmDeleteUser(String userId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete User'),
            content: const Text(
              'Are you sure you want to delete this user? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User deletion is disabled in this demo'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  // In a real app, you would delete the user:
                  // _usersCollection.doc(userId).delete();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
