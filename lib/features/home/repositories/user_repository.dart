import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/firebase_service.dart';
import '../models/user_model.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

class UserRepository {
  final FirebaseService _service = FirebaseService();

  Stream<UserModel> getUser(String uid) {
    return _service.streamUser(uid).map((snapshot) {
      final data = snapshot.data();
      if (data != null) {
        return UserModel.fromMap(snapshot.id, data);
      } else {
        throw Exception("User not found");
      }
    });
  }
}
