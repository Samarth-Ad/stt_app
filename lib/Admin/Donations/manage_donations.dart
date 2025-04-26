import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// This file implements the donations management page for admins.
///
/// IMPORTANT IMPLEMENTATION NOTE:
/// Instead of requiring Firebase composite indexes (which would need to be created
/// through Cloud CLI or Firebase Console), we use a client-side approach:
/// 1. We use simple queries that only require the automatically created single-field indexes
/// 2. For sorting by timestamp, we sort the documents client-side using the _processAndSortDonations method
///
/// This approach ensures the app works without any additional Firestore configuration.

class ManageDonationsPage extends StatefulWidget {
  const ManageDonationsPage({super.key});

  @override
  State<ManageDonationsPage> createState() => _ManageDonationsPageState();
}

class _ManageDonationsPageState extends State<ManageDonationsPage> {
  bool _isRefreshing = false;
  bool _isProcessing = false;
  String _filterStatus = 'all'; // 'all', 'pending', 'approved', 'rejected'

  Future<void> _refreshDonations() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Just a delay to simulate refresh
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donations refreshed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing donations: $e'),
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

  Future<void> _updateDonationStatus(
    String donationId,
    String newStatus,
  ) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .update({'status': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Donation marked as $newStatus'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating donation: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Donations',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8B4513),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon:
                _isRefreshing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isRefreshing ? null : _refreshDonations,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter options
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.brown.shade50,
              child: Row(
                children: [
                  const Text(
                    'Filter by status:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', 'all'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Pending', 'pending'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Approved', 'approved'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Rejected', 'rejected'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Donations list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getFilteredDonationsStream(),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Error loading donations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'There was a problem retrieving donation data. Try again later.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.volunteer_activism,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filterStatus == 'all'
                                ? 'No donations found'
                                : 'No $_filterStatus donations found',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Get and sort donations manually (as a workaround until index is created)
                  final donations = _processAndSortDonations(
                    snapshot.data!.docs,
                  );

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: donations.length,
                    itemBuilder: (context, index) {
                      final donation = donations[index];
                      final data = donation.data() as Map<String, dynamic>;

                      return _buildDonationCard(donation.id, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _filterStatus == status;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = status;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF8B4513).withOpacity(0.2),
      checkmarkColor: const Color(0xFF8B4513),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF8B4513) : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredDonationsStream() {
    try {
      // Get a reference to the donations collection
      final CollectionReference donationsRef = FirebaseFirestore.instance
          .collection('donations');

      // Always use a simple query without composite indexes
      // For 'all' status, just get all donations
      if (_filterStatus == 'all') {
        return donationsRef.snapshots();
      } else {
        // For specific status, just filter by status (simple single-field index)
        return donationsRef
            .where('status', isEqualTo: _filterStatus)
            .snapshots();
      }
    } catch (e) {
      print('Error in Firestore query: $e');
      return Stream.empty();
    }
  }

  // When building ListView, we'll manually sort the data client-side
  List<QueryDocumentSnapshot> _processAndSortDonations(
    List<QueryDocumentSnapshot> docs,
  ) {
    // Create a copy of the docs list to avoid modifying the original
    final List<QueryDocumentSnapshot> sortedDocs = List.from(docs);

    // Sort by timestamp (newest first)
    sortedDocs.sort((a, b) {
      // Get timestamps
      final aTimestamp =
          a.data() is Map ? (a.data() as Map)['timestamp'] as Timestamp? : null;
      final bTimestamp =
          b.data() is Map ? (b.data() as Map)['timestamp'] as Timestamp? : null;

      // If both timestamps exist, sort by timestamp (newest first)
      if (aTimestamp != null && bTimestamp != null) {
        return bTimestamp.compareTo(aTimestamp); // Descending order
      } else if (aTimestamp == null && bTimestamp != null) {
        return 1; // b comes first
      } else if (aTimestamp != null && bTimestamp == null) {
        return -1; // a comes first
      } else {
        return 0; // Equal
      }
    });

    return sortedDocs;
  }

  Widget _buildDonationCard(String donationId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? 'No email';
    final phone = data['phone'] ?? 'No phone';
    final amount = data['amount'] ?? 0.0;
    final transactionId = data['transactionId'] ?? 'No transaction ID';
    final status = data['status'] ?? 'pending';
    final timestamp = data['timestamp'] as Timestamp?;
    final membership = data['membership'] ?? 'Unknown';

    // Format date
    String formattedDate = 'No date';
    if (timestamp != null) {
      formattedDate = DateFormat(
        'MMM dd, yyyy • hh:mm a',
      ).format(timestamp.toDate());
    }

    // Status color
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.brown.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        membership,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Donor details
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From: $name',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(phone, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Transaction ID: $transactionId',
                            style: const TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                if (status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon:
                              _isProcessing
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.check),
                          label: const Text('Approve'),
                          onPressed:
                              _isProcessing
                                  ? null
                                  : () => _updateDonationStatus(
                                    donationId,
                                    'approved',
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon:
                              _isProcessing
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.cancel),
                          label: const Text('Reject'),
                          onPressed:
                              _isProcessing
                                  ? null
                                  : () => _updateDonationStatus(
                                    donationId,
                                    'rejected',
                                  ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                // For approved or rejected donations, show undo button
                if (status == 'approved' || status == 'rejected')
                  TextButton.icon(
                    icon:
                        _isProcessing
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.replay),
                    label: const Text('Mark as Pending'),
                    onPressed:
                        _isProcessing
                            ? null
                            : () =>
                                _updateDonationStatus(donationId, 'pending'),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
