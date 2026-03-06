import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String name;
  final String description;
  final String status;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String categoryId;
  final int baseTicketPrice;
  final int totalSeat;
  final int bookedSeats;
  final String promoterId;
  final DateTime createdAt;
  final String poster;
  final String? videoUrl; // 👈 added
  final List<String> gallery;
  final Map<String, dynamic> venueInfo;
  final Map<String, dynamic> about;
  final List<Map<String, dynamic>> ticketCategories;
  final List<Map<String, dynamic>> artistDetails;
  final double lat;
  final double long;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.categoryId,
    required this.baseTicketPrice,
    required this.totalSeat,
    required this.bookedSeats,
    required this.promoterId,
    required this.createdAt,
    required this.poster,
    this.videoUrl, // 👈 added
    required this.gallery,
    required this.venueInfo,
    required this.about,
    required this.ticketCategories,
    required this.artistDetails,
    required this.lat,
    required this.long,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Event',
      description: json['description'] ?? 'No description available',
      status: json['status'] ?? 'active',
      startTime: _parseDateTime(json['startTime']),
      endTime: _parseDateTime(json['endTime']),
      location: json['location'] ?? 'Location TBA',
      categoryId: json['categoryId'] ?? '',
      baseTicketPrice: (json['baseTicketPrice'] is int)
          ? json['baseTicketPrice']
          : int.tryParse(json['baseTicketPrice'].toString()) ?? 0,
      totalSeat: (json['totalSeat'] is int)
          ? json['totalSeat']
          : int.tryParse(json['totalSeat'].toString()) ?? 0,
      bookedSeats: (json['bookedSeats'] is int)
          ? json['bookedSeats']
          : int.tryParse(json['bookedSeats'].toString()) ?? 0,
      promoterId: json['promoterId'] ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      poster: json['poster']?.toString().isNotEmpty == true
          ? json['poster']
          : 'https://via.placeholder.com/400x200.png?text=No+Poster', // 👈 fallback
      videoUrl: json['videoUrl'], // 👈 added
      gallery: List<String>.from(json['gallery'] ?? []),
      venueInfo: Map<String, dynamic>.from(json['venueInfo'] ?? {}),
      about: Map<String, dynamic>.from(json['about'] ?? {}),
      ticketCategories: List<Map<String, dynamic>>.from(
        json['ticketCategories'] ?? [],
      ),
      artistDetails: List<Map<String, dynamic>>.from(
        json['artistDetails'] ?? [],
      ),
      lat: double.tryParse(json['lat'].toString()) ?? 0.0,
      long: double.tryParse(json['long'].toString()) ?? 0.0,
    );
  }

  // Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) {
      return DateTime.now();
    }

    if (dateTime is DateTime) {
      return dateTime;
    }

    if (dateTime is Timestamp) {
      return dateTime.toDate();
    }

    if (dateTime is String) {
      return DateTime.tryParse(dateTime) ?? DateTime.now();
    }

    if (dateTime is Map) {
      if (dateTime.containsKey('_seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(
          dateTime['_seconds'] * 1000 +
              (dateTime['_nanoseconds'] ?? 0) ~/ 1000000,
        );
      }
    }

    return DateTime.now();
  }
}
