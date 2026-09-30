import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_model.dart';

final historyRepositoryProvider = Provider((ref) => HistoryRepository());

class HistoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<ScanModel>> getScanHistoryStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    // Streams the specific user's scan sub-collection in real-time
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('scans')
        .orderBy('timestamp', descending: true) // Newest first
        .snapshots() 
        .map((snapshot) {
      return snapshot.docs.map((doc) => ScanModel.fromMap(doc.data())).toList();
    });
  }
}