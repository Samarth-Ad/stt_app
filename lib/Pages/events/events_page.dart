import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current date for highlighting today's events
    final DateTime now = DateTime.now();
    final String todayDate = DateFormat('yyyy-MM-dd').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Events',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF8B4513)),
            onPressed: () {
              Navigator.pushNamed(context, '/events-history');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's Events Section
              const Text(
                'Today\'s Events',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 16),
              _buildEventCard(
                imageUrl: 'assets/stt_logo.png',
                title: 'Blood Donation Camp',
                date: DateFormat('MMMM dd, yyyy').format(now),
                location: 'City Hospital, Ahmedabad',
                time: '10:00 AM - 4:00 PM',
                isToday: true,
              ),

              const SizedBox(height: 24),

              // Upcoming Events Section
              const Text(
                'Upcoming Events',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 16),
              _buildEventCard(
                imageUrl: 'assets/stt_logo.png',
                title: 'Food Distribution Drive',
                date: 'April 2, 2025',
                location: 'Slum Areas, Ahmedabad',
                time: '9:00 AM - 1:00 PM',
                isToday: false,
              ),
              _buildEventCard(
                imageUrl: 'assets/stt_logo.png',
                title: 'Tree Plantation Drive',
                date: 'April 10, 2025',
                location: 'City Park, Ahmedabad',
                time: '8:00 AM - 12:00 PM',
                isToday: false,
              ),
              _buildEventCard(
                imageUrl: 'assets/stt_logo.png',
                title: 'Clothes Donation Drive',
                date: 'April 15, 2025',
                location: 'Orphanage, Ahmedabad',
                time: '11:00 AM - 3:00 PM',
                isToday: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard({
    required String imageUrl,
    required String title,
    required String date,
    required String location,
    required String time,
    required bool isToday,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isToday ? Border.all(color: Colors.green, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Event date
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(date, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                // Event time
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(time, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                // Event location
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(location, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),
                // Register button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.how_to_reg),
                    label: const Text('Register'),
                    onPressed: () {
                      // Handle registration
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4513),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
