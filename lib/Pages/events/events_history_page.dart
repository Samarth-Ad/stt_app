import 'package:flutter/material.dart';

class EventsHistoryPage extends StatelessWidget {
  const EventsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Events History',
          style: TextStyle(
            color: Color(0xFF8B4513),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF8B4513)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Past Events',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 16),
              // List of past events
              _buildEventCard(
                imageUrl: 'assets/stt_logo.png',
                title: 'Blood Donation Camp',
                date: 'March 15, 2025',
                location: 'City Hospital, Ahmedabad',
                participants: 75,
              ),
              _buildEventCard(
                imageUrl: 'assets/stt_logo.png',
                title: 'Food Distribution Drive',
                date: 'February 28, 2025',
                location: 'Slum Areas, Ahmedabad',
                participants: 120,
              ),
              _buildEventCard(
                imageUrl: 'assets/stt_logo.png',
                title: 'Tree Plantation Drive',
                date: 'January 26, 2025',
                location: 'City Park, Ahmedabad',
                participants: 95,
              ),
              _buildEventCard(
                imageUrl: 'assets/stt_logo.png',
                title: 'Clothes Donation Drive',
                date: 'December 25, 2024',
                location: 'Orphanage, Ahmedabad',
                participants: 55,
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
    required int participants,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
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
                // Event location
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(location, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),
                // Participants info
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.people,
                        size: 16,
                        color: Color(0xFF8B4513),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$participants participants',
                        style: const TextStyle(
                          color: Color(0xFF8B4513),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
