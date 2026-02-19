import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

// Use a simple enum for the filters
enum AnalyticsFilter { week, month, allTime }

// The Provider
final analyticsProvider = AsyncNotifierProvider<AnalyticsController, Map<String, double>>(() {
  return AnalyticsController();
});

class AnalyticsController extends AsyncNotifier<Map<String, double>> {
  // We store the current filter state here inside the controller
  AnalyticsFilter _currentFilter = AnalyticsFilter.allTime;
  AnalyticsFilter get currentFilter => _currentFilter;

  @override
  FutureOr<Map<String, double>> build() async {
    return _fetchAnalytics();
  }

  Future<Map<String, double>> _fetchAnalytics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    if (_currentFilter == AnalyticsFilter.allTime) {
      // INSTANT: Fetch from Category Counter in User Document
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data()?['categoryCounts'] as Map<String, dynamic>? ?? {};
      
      // Convert Map<String, int> to Map<String, double> for the UI bars
      return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } else {
      // DYNAMIC: Query Scans sub-collection for specific range
      DateTime now = DateTime.now();
      DateTime startDate = _currentFilter == AnalyticsFilter.week 
          ? now.subtract(const Duration(days: 7)) 
          : DateTime(now.year, now.month - 1, now.day);

      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scans')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(startDate))
          .get();

      Map<String, double> counts = {};
      for (var doc in query.docs) {
        final cat = doc.data()['category'] ?? 'General';
        counts[cat] = (counts[cat] ?? 0.0) + 1.0;
      }
      return counts;
    }
  }

  // Method to change filter and refresh UI
  Future<void> changeFilter(AnalyticsFilter filter) async {
    _currentFilter = filter;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchAnalytics());
  }
}