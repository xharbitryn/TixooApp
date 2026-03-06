/// Models for the Home Screen data
/// These are placeholder models for UI development.
/// Replace with actual Firebase models during integration.

class LocationData {
  final String city;
  final String state;
  final String country;

  const LocationData({
    required this.city,
    required this.state,
    required this.country,
  });

  String get formatted => '$city, $state, $country';
  String get shortFormatted => '$city\n$state, $country';
}

class CategoryItem {
  final String id;
  final String label;
  final String iconPath;
  final bool isSelected;

  const CategoryItem({
    required this.id,
    required this.label,
    required this.iconPath,
    this.isSelected = false,
  });

  CategoryItem copyWith({bool? isSelected}) {
    return CategoryItem(
      id: id,
      label: label,
      iconPath: iconPath,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class TrendingEvent {
  final String id;
  final String imageUrl;
  final String dateTime;
  final String title;
  final String venue;
  final String city;
  final double priceStarting;

  const TrendingEvent({
    required this.id,
    required this.imageUrl,
    required this.dateTime,
    required this.title,
    required this.venue,
    required this.city,
    required this.priceStarting,
  });

  String get priceFormatted => '₹${priceStarting.toStringAsFixed(0)} Onwards';
}

class ArtistData {
  final String id;
  final String name;
  final String imageUrl;
  final bool isVerified;

  const ArtistData({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.isVerified = true,
  });
}

class EventData {
  final String id;
  final String imageUrl;
  final String title;
  final String venue;
  final String city;
  final double price;
  final String dayLabel;
  final String monthLabel;
  final List<String> tags;

  const EventData({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.venue,
    required this.city,
    required this.price,
    required this.dayLabel,
    required this.monthLabel,
    this.tags = const [],
  });

  String get priceFormatted => '₹${price.toStringAsFixed(0)}';
}

class OfferData {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? backgroundColor;

  const OfferData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.backgroundColor,
  });
}

class PromoterData {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final int totalEvents;

  const PromoterData({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    this.totalEvents = 0,
  });
}

class PlusBenefit {
  final String id;
  final String title;
  final String imageUrl;
  final int backgroundColor;

  const PlusBenefit({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.backgroundColor,
  });
}

class FilterChip {
  final String label;
  final bool isSelected;
  final bool hasIcon;

  const FilterChip({
    required this.label,
    this.isSelected = false,
    this.hasIcon = false,
  });
}
