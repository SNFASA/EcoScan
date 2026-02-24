import 'package:cloud_firestore/cloud_firestore.dart';

class RecyclingCenterModel {
  final String name;
  final String address;
  final GeoPoint? location; // Use GeoPoint (capitalized)
  final String type;
  final int rating;
  final List<String> acceptedCategories; // Use List<String>
  final Timestamp createdAt;

  RecyclingCenterModel({
    required this.name,
    required this.address,
    this.location,
    required this.type,
    required this.rating,
    required this.acceptedCategories,
    required this.createdAt,
  });

  // Convert Firestore Map to Model
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

