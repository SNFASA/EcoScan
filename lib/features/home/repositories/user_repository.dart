import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<UserModel> getUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data != null) {
        return UserModel.fromMap(snapshot.id, data);
      } else {
        throw Exception("User not found");
      }
    });
  }

  Future<void> updateUserSettings(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }
}