import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

final userControllerProvider =
    StreamProvider.family<UserModel, String>((ref, uid) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUser(uid);
});
