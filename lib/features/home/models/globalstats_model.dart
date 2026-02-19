import 'package:cloud_firestore/cloud_firestore.dart';

class GlobalstatsModel {
  final int totaluser;
  final int totalScans;
  final double totalCo2Offset;
  final int totalRecyclingCenters;
  final Timestamp lastUpdated;

  GlobalstatsModel({
    required this.totaluser,
    required this.totalScans,
    required this.totalCo2Offset,
    required this.totalRecyclingCenters,
    required this.lastUpdated,
  });

  factory GlobalstatsModel.fromMap(Map<String, dynamic> json) {
    return GlobalstatsModel(
      totaluser: json['totaluser'] ?? 0,
      totalScans: json['totalScans'] ?? 0,
      totalCo2Offset: (json['totalCo2Offset'] ?? 0.0).toDouble(),
      totalRecyclingCenters: json['totalRecyclingCenters'] ?? 0,
      lastUpdated: json['lastUpdated'] ?? Timestamp.now(),
    );
  }
}