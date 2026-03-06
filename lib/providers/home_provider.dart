// lib/providers/home_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/home_models.dart';

class HomeData {
  final List<TrendingEvent> trendingEvents;
  final List<EventData> allEvents;
  final List<ArtistData> artists;
  final List<PromoterData> promoters;

  HomeData({
    required this.trendingEvents,
    required this.allEvents,
    required this.artists,
    required this.promoters,
  });
}

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final firestore = FirebaseFirestore.instance;

  // ==========================================
  // 1. Fetch Events
  // ==========================================
  final eventsSnap = await firestore.collection('Events').limit(15).get();
  debugPrint('--- FIREBASE FETCH: Found ${eventsSnap.docs.length} Events ---');

  List<TrendingEvent> trending = [];
  List<EventData> all = [];

  for (var doc in eventsSnap.docs) {
    final data = doc.data();
    final id = doc.id;
    final title = data['name'] ?? 'Unknown Event';

    final imageUrl =
        data['poster'] ??
        (data['gallery'] != null && (data['gallery'] as List).isNotEmpty
            ? data['gallery'][0]
            : 'https://via.placeholder.com/600x400?text=Event');

    final basePrice = (data['baseTicketPrice'] ?? 0).toDouble();
    final city = data['city'] ?? 'TBA';

    final venueInfo = data['venueInfo'] as Map<String, dynamic>? ?? {};
    final venueName = venueInfo['name'] ?? 'TBA';

    String dateTimeStr = 'TBA';
    String dayLabel = '--';
    String monthLabel = '--';

    if (data['startTime'] != null && data['startTime'] is Timestamp) {
      DateTime dt = (data['startTime'] as Timestamp).toDate();
      dateTimeStr = '${DateFormat('EEEE d MMMM, h:mm a').format(dt)} onwards';
      dayLabel = DateFormat('EEE').format(dt);
      monthLabel = DateFormat('MMM').format(dt);
    }

    all.add(
      EventData(
        id: id,
        imageUrl: imageUrl,
        title: title,
        venue: venueName,
        city: city,
        price: basePrice,
        dayLabel: dayLabel,
        monthLabel: monthLabel,
        tags: [data['eventCategory'] ?? 'Event'],
      ),
    );

    if (trending.length < 4) {
      trending.add(
        TrendingEvent(
          id: id,
          imageUrl: imageUrl,
          dateTime: dateTimeStr,
          title: title,
          venue: venueName,
          city: city,
          priceStarting: basePrice,
        ),
      );
    }
  }

  // ==========================================
  // 2. Fetch Artists
  // ==========================================
  final artistsSnap = await firestore.collection('Artists').limit(8).get();
  debugPrint(
    '--- FIREBASE FETCH: Found ${artistsSnap.docs.length} Artists ---',
  );

  List<ArtistData> artistsList = [];
  for (var doc in artistsSnap.docs) {
    final data = doc.data();
    artistsList.add(
      ArtistData(
        id: doc.id,
        name: data['name'] ?? 'Unknown Artist',
        imageUrl:
            data['image'] ?? 'https://via.placeholder.com/200?text=Artist',
        isVerified: true,
      ),
    );
  }

  // ==========================================
  // 3. Fetch Promoters (SMART FETCH)
  // ==========================================
  // Try lowercase first
  QuerySnapshot promotersSnap = await firestore
      .collection('promoters')
      .limit(5)
      .get();

  // If lowercase fails, the database likely used an uppercase 'P' like the other collections
  if (promotersSnap.docs.isEmpty) {
    debugPrint(
      '--- "promoters" was empty. Trying "Promoters" (Capital P)... ---',
    );
    promotersSnap = await firestore.collection('Promoters').limit(5).get();
  }

  debugPrint(
    '--- FIREBASE FETCH: Found ${promotersSnap.docs.length} Promoters ---',
  );

  List<PromoterData> promotersList = [];
  for (var doc in promotersSnap.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final publicData = data['publicdata'] as Map<String, dynamic>? ?? data;

    // Count visible events
    int totalEvents = 0;
    if (publicData['visibleEvents'] != null &&
        publicData['visibleEvents'] is Map) {
      totalEvents = (publicData['visibleEvents'] as Map).keys.length;
    }

    // Safely map the exact 'ratings' field you shared from your database
    double parsedRating = 4.8; // Fallback
    if (data['ratings'] != null) {
      parsedRating = (data['ratings'] as num).toDouble();
    } else if (publicData['ratings'] != null) {
      parsedRating = (publicData['ratings'] as num).toDouble();
    }

    promotersList.add(
      PromoterData(
        id: doc.id,
        name: publicData['name'] ?? data['displayName'] ?? 'Tixoo Promoter',
        description: publicData['bio'] ?? 'Event Organizer on Tixoo',
        imageUrl:
            publicData['photoURL'] ??
            data['photoURL'] ??
            'https://via.placeholder.com/300?text=Promoter',
        rating: parsedRating,
        totalEvents: totalEvents,
      ),
    );
  }

  return HomeData(
    trendingEvents: trending,
    allEvents: all,
    artists: artistsList,
    promoters: promotersList,
  );
});
