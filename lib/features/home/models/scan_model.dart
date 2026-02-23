import 'package:cloud_firestore/cloud_firestore.dart';

class ScanModel {
  final String category;
  final double co2Saved;
  final double confidenceScore;
  final String imageUrl;
  final int pointsEarned;
  final Timestamp timestamp;
  final String wasteType;
  final String weekId;

  ScanModel({
    required this.category,
    required this.co2Saved,
    required this.confidenceScore,
    required this.imageUrl,
    required this.pointsEarned,
    required this.timestamp,
    required this.wasteType,
    required this.weekId,
  });

  factory ScanModel.fromMap(Map<String, dynamic> json) {
    return ScanModel(
      category: json['category'] ?? '',
      co2Saved: (json['co2Saved'] ?? 0.0).toDouble(),
      confidenceScore: (json['confidenceScore'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      pointsEarned: json['pointsEarned'] ?? 0,
      timestamp: json['timestamp'] ?? Timestamp.now(),
      wasteType: json['wasteType'] ?? '',
      weekId: json['weekId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'co2Saved': co2Saved,
      'confidenceScore': confidenceScore,
      'imageUrl': imageUrl,
      'pointsEarned': pointsEarned,
      'timestamp': timestamp,
      'wasteType': wasteType,
      'weekId': weekId,
    };
  }
}