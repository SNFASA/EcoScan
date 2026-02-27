import 'package:cloud_firestore/cloud_firestore.dart';

class RecyclingCenterModel {
  final String name;
  final String address;
  final GeoPoint? location;
  final String type;
  final int rating;
  final List<String> acceptedCategories;
  final Timestamp createdAt;

  // 🌟 NEW: Added placeId to help fetch phone numbers later!
  final String? placeId;

  RecyclingCenterModel({
    required this.name,
    required this.address,
    this.location,
    required this.type,
    required this.rating,
    required this.acceptedCategories,
    required this.createdAt,
    this.placeId,
  });

  // 1️⃣ YOUR EXISTING FIRESTORE MAPPER (Untouched)
  factory RecyclingCenterModel.fromMap(Map<String, dynamic> json) {
    return RecyclingCenterModel(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      location: json['location'] as GeoPoint?,
      type: json['type'] ?? '',
      rating: json['rating'] ?? 0,
      acceptedCategories: List<String>.from(json['acceptedCategories'] ?? []),
      createdAt: json['createdAt'] ?? Timestamp.now(),
    );
  }

  // 2️⃣ THE NEW GOOGLE PLACES MAPPER
  factory RecyclingCenterModel.fromGooglePlaces(Map<String, dynamic> json, String searchCategory) {
    // Extract coordinates
    final lat = json['geometry']?['location']?['lat'] ?? 0.0;
    final lng = json['geometry']?['location']?['lng'] ?? 0.0;

    // Guess the categories based on what the user searched for
    final assignedCategories = searchCategory == "All"
        ? ["Plastic", "Paper", "Metal", "Glass"] // Defaults for a general search
        : [searchCategory];

    // Google returns ratings as doubles (e.g., 4.5), but your model uses int
    final dynamic rawRating = json['rating'] ?? 0;
    final int parsedRating = rawRating is int ? rawRating : (rawRating as double).toInt();

    return RecyclingCenterModel(
      placeId: json['place_id'], // Google's unique ID for the place
      name: json['name'] ?? 'Unknown Center',
      address: json['formatted_address'] ?? 'No address provided',
      location: GeoPoint(lat, lng), // 🌟 We still use Firestore's GeoPoint!
      type: (json['types'] != null && (json['types'] as List).isNotEmpty)
          ? json['types'][0].toString().replaceAll('_', ' ')
          : 'Recycling',
      rating: parsedRating,
      acceptedCategories: assignedCategories,
      createdAt: Timestamp.now(), // Live data doesn't have a creation date, so we use now
    );
  }

  // Helper method to convert Model back to Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'location': location,
      'type': type,
      'rating': rating,
      'acceptedCategories': acceptedCategories,
      'createdAt': createdAt,
    };
  }
}