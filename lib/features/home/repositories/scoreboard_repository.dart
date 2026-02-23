import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class ScoreboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🌟 CHANGED: Future to Stream, and .get() to .snapshots()
  Stream<List<UserModel>> getTopWeeklyUsersStream(int limit) {
    return _firestore
        .collection('users')
        .orderBy('weeklyPoints', descending: true)
        .limit(limit)
        .snapshots() // <-- This is the magic word for real-time updates!
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return UserModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}