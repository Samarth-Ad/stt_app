import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String? id;
  final String title;
  final String location;
  final DateTime date;
  final String time;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;

  Event({
    this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.time,
    required this.imageUrl,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'date': date.millisecondsSinceEpoch,
      'time': time,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Create an Event object from a map (from Firestore)
  factory Event.fromMap(Map<String, dynamic> map) {
    // Handle different date formats from Firestore
    DateTime parseDate(dynamic dateValue) {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else {
        return DateTime.now(); // Fallback
      }
    }

    // Handle different createdAt formats from Firestore
    DateTime parseCreatedAt(dynamic createdAtValue) {
      if (createdAtValue is Timestamp) {
        return createdAtValue.toDate();
      } else if (createdAtValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(createdAtValue);
      } else {
        return DateTime.now(); // Fallback
      }
    }

    return Event(
      id: map['id'],
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      date: parseDate(map['date']),
      time: map['time'] ?? '',
      imageUrl: map['imageUrl'] ?? 'assets/stt_logo.png',
      isActive: map['isActive'] ?? true,
      createdAt:
          map.containsKey('createdAt')
              ? parseCreatedAt(map['createdAt'])
              : DateTime.now(),
    );
  }

  // Create a copy of this event with different values
  Event copyWith({
    String? id,
    String? title,
    String? location,
    DateTime? date,
    String? time,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      date: date ?? this.date,
      time: time ?? this.time,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
