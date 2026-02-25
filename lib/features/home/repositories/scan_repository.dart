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

    try {
      // Fetch the current user data to check the last recorded week
      final userDoc = await userRef.get();
      
      WriteBatch batch = _firestore.batch();

      // 1. Save individual scan details
      batch.set(scanRef, scan.toMap());

      // 2. Weekly Reset Logic
      // We check if the 'lastScanWeekId' in Firestore matches the scan's current 'weekId'
      bool isNewWeek = true;
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final String lastWeekId = data['lastScanWeekId'] ?? "";
        
        // If the stored week ID matches the current scan's week ID, it's NOT a new week
        if (lastWeekId == scan.weekId) {
          isNewWeek = false;
        }
      }

      // 3. Update user's aggregate stats
      if (isNewWeek) {
        // RESET: Start weekly points fresh for the new week
        batch.update(userRef, {
          'categoryCounts.${scan.category}': FieldValue.increment(1),
          'totalScans': FieldValue.increment(1),
          'ecoPoints': FieldValue.increment(scan.pointsEarned),
          'weeklyPoints': scan.pointsEarned, // Set to current scan points (Overwrite old week)
          'co2Offset': FieldValue.increment(scan.co2Saved),
          'lastScanWeekId': scan.weekId, // Update the tracking week ID
        });
      } else {
        // INCREMENT: Add to existing weekly points
        batch.update(userRef, {
          'categoryCounts.${scan.category}': FieldValue.increment(1),
          'totalScans': FieldValue.increment(1),
          'ecoPoints': FieldValue.increment(scan.pointsEarned),
          'weeklyPoints': FieldValue.increment(scan.pointsEarned), // Correctly updating the scoreboard
          'co2Offset': FieldValue.increment(scan.co2Saved),
          'lastScanWeekId': scan.weekId,
        });
      }

      // Commit all changes at once
      await batch.commit();
      
    } catch (e) {
      // Log error for debugging
      print("Error saving scan and updating scoreboard: $e");
      rethrow;
    }
  }
}