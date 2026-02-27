import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/globalstats_model.dart';

final globalStatsProvider = StreamProvider<GlobalstatsModel>((ref) {
  // Log that the user is viewing global stats
  FirebaseAnalytics.instance.logEvent(name: 'view_global_dashboard');
  
  return FirebaseFirestore.instance
      .collection('stats')
      .doc('global')
      .snapshots()
      .map((snapshot) => GlobalstatsModel.fromMap(snapshot.data() ?? {}));
});