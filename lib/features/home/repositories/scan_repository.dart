import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_model.dart';

final scanRepositoryProvider = Provider((ref) => ScanRepository());

class ScanRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveScan(ScanModel scan) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userRef = _firestore.collection('users').doc(uid);
    final scanRef = userRef.collection('scans').doc();

    WriteBatch batch = _firestore.batch();

    // 1. Save scan details
    batch.set(scanRef, scan.toMap());

    // 2. Update user's aggregate stats and check week reset logic
    batch.update(userRef, {
      'totalScans': FieldValue.increment(1),
      'ecoPoints': FieldValue.increment(scan.pointsEarned),
      'co2Offset': FieldValue.increment(scan.co2Saved),
      'weeklyPoints': FieldValue.increment(scan.pointsEarned),
    });

    await batch.commit();
  }
}