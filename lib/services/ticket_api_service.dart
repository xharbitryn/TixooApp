import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class TicketApiService {
  // 🚀 Replace this with your actual backend URL (e.g., https://api.tixoo.com)
  static const String baseUrl = 'https://tixoo.ashukumar.me';

  // Helper to get the Firebase Auth Token
  static Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  // Helper for authenticated headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 1. Get Event Occurrences
  static Future<List<dynamic>> getOccurrences(String eventId) async {
    final url = Uri.parse('$baseUrl/api/public/events/$eventId/occurrences');
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['occurrences'] ?? [];
    }
    throw Exception('Failed to load occurrences');
  }

  // 2. Get Ticket Categories (Pricing & Details)
  static Future<List<dynamic>> getTicketCategories(String eventId) async {
    final url = Uri.parse(
      '$baseUrl/api/public/events/$eventId/tickets/categories',
    );
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    }
    throw Exception('Failed to load categories');
  }

  // 3. Get Ticket Availability (Inventory limits)
  static Future<Map<String, dynamic>> getTicketAvailability(
    String eventId, {
    String? occurrenceId,
  }) async {
    // If you need to filter availability by occurrence, you can append it as a query param
    final query = occurrenceId != null ? '?occurrenceId=$occurrenceId' : '';
    final url = Uri.parse(
      '$baseUrl/api/public/events/$eventId/tickets/availability$query',
    );
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    }
    throw Exception('Failed to load availability');
  }

  // 4. Reserve Tickets (Locks inventory temporarily)
  static Future<bool> reserveTickets({
    required String eventId,
    required String categoryId,
    required int quantity,
    String? occurrenceId,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/bookings/reserve-tickets');
    final headers = await _getHeaders();
    final body = json.encode({
      'eventId': eventId,
      'categoryId': categoryId,
      'quantity': quantity,
      if (occurrenceId != null) 'occurrenceId': occurrenceId,
    });

    final response = await http.post(url, headers: headers, body: body);
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // 5. Create Booking (Generates Razorpay Order ID)
  static Future<Map<String, dynamic>> createBooking({
    required String eventId,
    required Map<String, int> selectedTickets, // categoryId : quantity
    String? occurrenceId,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/bookings/create-booking');
    final headers = await _getHeaders();

    final ticketsList = selectedTickets.entries
        .map((e) => {'categoryId': e.key, 'quantity': e.value})
        .toList();

    final body = json.encode({
      'eventId': eventId,
      'tickets': ticketsList,
      if (occurrenceId != null) 'occurrenceId': occurrenceId,
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body); // Should return order_id for Razorpay
    }
    throw Exception('Failed to create booking');
  }
}
