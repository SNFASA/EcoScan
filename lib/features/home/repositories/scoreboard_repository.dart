import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class ScoreboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserModel>> getTopWeeklyUsers(int limit) async {
    final querySnapshot = await _firestore
        .collection('users')
        .orderBy('weeklyPoints', descending: true)
        .limit(limit)
        .get();

    return querySnapshot.docs.map((doc) {
      return UserModel.fromMap(doc.id, doc.data());
    }).toList();
  }
}